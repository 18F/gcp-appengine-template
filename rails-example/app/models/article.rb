class Article < ApplicationRecord
	# NIST-800-53-SI-10
	validates :title, presence: true,
				length: { minimum: 5 }
end
