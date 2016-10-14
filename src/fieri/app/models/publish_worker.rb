require 'sidekiq'
require 'net/http'

class PublishWorker
  include ::Sidekiq::Worker

  def perform(cookbook_name)
    parsed = JSON.parse(get_supermarket_response(cookbook_name))

    if parsed['name'] == cookbook_name
      exists_failure = false
    else
      exists_failure = true
    end

    if parsed['deprecated'] == true
      deprecated_failure = true
    else
      deprecated_failure = false
    end

    if exists_failure == true || deprecated_failure == true
      failure = true
    else
      failure = false
    end

#    parsed['deprecated'] == true ? failure = true : failure = false

    Net::HTTP.post_form(
      URI.parse("#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbook-versions/publish_evaluation"),
      fieri_key: ENV['FIERI_KEY'],
      cookbook_name: cookbook_name,
      publish_failure: failure,
      publish_feedback: publish_feedback(cookbook_name)
    )
  end

  private

  def supermarket_uri(cookbook_name)
    URI.parse("#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbooks/#{cookbook_name}")
  end

  def get_supermarket_response(cookbook_name)
    Net::HTTP.get(supermarket_uri(cookbook_name))
  end

  def publish_feedback(cookbook_name)
    "#{cookbook_name} not found in Supermarket"
  end
end
