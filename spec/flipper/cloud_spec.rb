require 'helper'
require 'flipper/cloud'
require 'flipper/instrumenters/memory'
require 'flipper/adapters/instrumented'
require 'flipper/adapters/pstore'
require 'rack/handler/webrick'

RSpec.describe Flipper::Cloud do
  before do
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")
  end

  context "initialize with token" do
    let(:token) { 'asdf' }

    before do
      @instance = described_class.new(token)
      memoized_adapter = @instance.adapter
      sync_adapter = memoized_adapter.adapter
      @http_adapter = sync_adapter.instance_variable_get('@remote')
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'returns cloud client' do
      expect(@instance).to be_instance_of(Flipper::Cloud::Client)
    end

    it 'configures instance to use http adapter' do
      expect(@http_adapter).to be_instance_of(Flipper::Adapters::Http)
    end

    it 'sets up correct url' do
      uri = URI(@http_adapter.client.url)
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.flippercloud.io')
      expect(uri.path).to eq('/adapter')
    end

    it 'sets correct token header' do
      headers = @http_client.instance_variable_get('@headers')
      expect(headers['FEATURE_FLIPPER_TOKEN']).to eq(token)
    end

    it 'uses cloud instrumenter wrapping noop' do
      expect(@instance.instrumenter).to be_instance_of(Flipper::Cloud::Instrumenter)
      expect(@instance.instrumenter.instrumenter).to be(Flipper::Instrumenters::Noop)
    end
  end

  context 'initialize with token and options' do
    before do
      stub_request(:get, /fakeflipper\.com/).to_return(status: 200, body: "{}")

      @instance = described_class.new('asdf', url: 'https://www.fakeflipper.com/sadpanda')
      memoized_adapter = @instance.adapter
      sync_adapter = memoized_adapter.adapter
      @http_adapter = sync_adapter.instance_variable_get('@remote')
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'sets correct url' do
      uri = URI(@http_adapter.client.url)
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.fakeflipper.com')
      expect(uri.path).to eq('/sadpanda')
    end
  end

  it 'can set instrumenter' do
    instrumenter = Flipper::Instrumenters::Memory.new
    instance = described_class.new('asdf', instrumenter: instrumenter)
    expect(instance.instrumenter).to be_instance_of(Flipper::Cloud::Instrumenter)
    expect(instance.instrumenter.instrumenter).to be(instrumenter)
  end

  it 'allows wrapping adapter with another adapter like the instrumented' do
    instance = described_class.new('asdf') do |config|
      config.adapter do |adapter|
        Flipper::Adapters::Instrumented.new(adapter)
      end
    end
    # instance.adapter is memoizable adapter instance
    expect(instance.adapter.adapter).to be_instance_of(Flipper::Adapters::Instrumented)
  end

  it 'can set debug_output' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(debug_output: STDOUT)).at_least(1)
    described_class.new('asdf', debug_output: STDOUT)
  end

  it 'can set read_timeout' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(read_timeout: 1)).at_least(1)
    described_class.new('asdf', read_timeout: 1)
  end

  it 'can set open_timeout' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(open_timeout: 1)).at_least(1)
    described_class.new('asdf', open_timeout: 1)
  end
end
