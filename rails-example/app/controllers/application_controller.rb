require 'digest'

class ApplicationController < ActionController::Base
	# check to make sure we are authenticated before going forward
	before_action :check_auth

	# set the current user depending on whether we are doing basic auth,
	# SSO, or local development
	def current_user
		idp = ENV.fetch('IDP_PROVIDER_URL') {''}
		basicauth_username = ENV.fetch('BASICAUTH_USER') {''}

		if idp != ''
			myuser = request.env['HTTP_X_FORWARDED_USER']
			if myuser.nil?
				logger.info 'missing HTTP_X_FORWARDED_USER: setting to anonymous'
				myuser = 'Anonymous'
			else
				logger.info "using HTTP_X_FORWARDED_USER from proxy: " + myuser
			end
		elsif basicauth_username != ''
			myuser = basicauth_username
			logger.info "setting username to BASICAUTH_USER: " + myuser
		else
			myuser = 'Anonymous'
			logger.info "no username set, using " + myuser
		end
		@current_user ||= myuser
	end
	helper_method :current_user

	# set basic auth if requested, and if we are not using SSO
	pw = ENV.fetch('BASICAUTH_PASSWORD') {''}
	idp = ENV.fetch('IDP_PROVIDER_URL') {''}
	basicauth_username = ENV.fetch('BASICAUTH_USER') {''}
	if pw != '' && idp == '' then
		logger.info "setting basic auth password for " + basicauth_username
		http_basic_authenticate_with name: basicauth_username, password: pw
	end

	private

	def check_auth
		# if we don't have a signature key, then
		# we are running locally and should thus let them in
		signature_key = ENV.fetch('SIGNATURE_KEY') {''}
		return if signature_key == ''

		# If we don't have an IDP set, then we are not doing SSO,
		# and thus should let them in.
		idp = ENV.fetch('IDP_PROVIDER_URL') {''}
		return if idp == ''

		# If we have a properly signed ZAP-Authorization header, then
		# it's the ZAP scanner, and we should let it in
		if ! request.headers['ZAP-Authorization'].nil?
			authheader = request.headers['ZAP-Authorization']
			tokenhash, token = authheader.split('_',2)
			uuid, datestamp = token.split('_',2)

			# Check that the token hasn't expired (scans run for 30 minutes max)
			if (Time.new.to_i - datestamp.to_i).abs > 1800
				logger.warn 'ZAP-Authorization has expired'
				render plain: "305 use proxy", status: 305
				return
			end

			# Check that the hash results are the same
			checktokenhash = Digest::SHA256.hexdigest(signature_key + '_' + token)
			if checktokenhash == tokenhash
				return
			else
				logger.warn 'ZAP-Authorization did not verify'
				render plain: "305 use proxy", status: 305
				return
			end
		end

		# Otherwise, check the HMAC signature
		if request.headers['GAP-Signature'].nil? 
			logger.warn 'missing GAP-Signature'
			render plain: "305 use proxy", status: 305
			return
		end
		if ApiAuth.authentic?(request, signature_key, :digest => 'sha1')
			logger.warn 'GAP-Signature did not verify'
			render plain: "305 use proxy", status: 305
			return
		end
	end
end
