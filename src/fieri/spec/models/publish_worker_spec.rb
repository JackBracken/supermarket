require 'rails_helper'

describe CollaboratorWorker do
  let(:pw) { PublishWorker.new }
  let(:cookbook_name) { 'greatcookbook' }
  let(:cookbook_response) { File.read('spec/support/cookbook_metrics_fixture.json') }
  let(:uri) { "#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbooks/#{cookbook_name}" }

  before do
    stub_request(:post, "#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbook-versions/publish_evaluation").
      to_return(:status => 200, :body => "", :headers => {})

    allow(Net::HTTP).to receive(:get).and_return(cookbook_response)
  end

  it 'calls the Supermarket API' do
    expect(Net::HTTP).to receive(:get).with(URI(uri)).and_return(cookbook_response)
    pw.perform(cookbook_name)
  end

  it 'parses the response as json' do
    expect(JSON).to receive(:parse).with(cookbook_response).and_return(cookbook_response)
    pw.perform(cookbook_name)
  end

  context 'checking whether the cookbook exists on supermarket' do
    context 'when it exists' do
      before do
        allow(JSON).to receive(:parse).and_return(cookbook_response)
      end

      it 'indicates that the publish metric passed' do
        pw.perform(cookbook_name)

        assert_requested(:post, "#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbook-versions/publish_evaluation", times: 1) do |req|
          expect(req.body).to include('publish_failure=false')
          req.body =~ /publish_feedback=.+/
        end
      end
    end

    context 'when it does not exist' do
      let(:cookbook_does_not_exist_json_response) { File.read('spec/support/cookbook_does_not_exist.json') }

      before do
        allow(Net::HTTP).to receive(:get).and_return(cookbook_does_not_exist_json_response)
      end

      it 'indicates that the publish metric failed' do
        pw.perform(cookbook_name)

        assert_requested(:post, "#{ENV['FIERI_SUPERMARKET_ENDPOINT']}/api/v1/cookbook-versions/publish_evaluation", times: 1) do |req|
          expect(req.body).to include('publish_failure=true')
        end
      end
    end
  end


end