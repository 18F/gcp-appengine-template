class ApplicationController < ActionController::Base
  before_action :check_hmacauth

  private

	def check_hmacauth
		signature_key = ENV.fetch('SIGNATURE_KEY') {''}
		return if signature_key == ''
		if request.headers['GAP-Signature'].nil? 
			pp 'missing GAP-Signature'
			render plain: "305 use proxy", status: 305
		end
		if ApiAuth.authentic?(request, signature_key, :digest => 'sha1')
			pp 'signature did not verify'
			render plain: "305 use proxy", status: 305
		end
	end
end
