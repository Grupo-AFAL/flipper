require 'helper'

RSpec.describe Flipper::Api::V1::Actions::RuleGate do
  let(:app) { build_api(flipper) }
  let(:actor) {
    Flipper::Actor.new('1', {
      "plan" => "basic",
      "age" => 21,
    })
  }
  let(:rule) { Flipper.property(:plan).eq("basic") }

  describe 'enable' do
    before do
      flipper[:my_feature].disable_rule
      post '/features/my_feature/rule', JSON.dump(rule.value),
        "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to eq(rule.value)
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable_rule(rule)
      delete '/features/my_feature/rule', JSON.dump({}),
        "CONTENT_TYPE" => "application/json"
    end

    it 'disables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with rule gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to be(nil)
    end
  end

  describe 'enable feature with slash in name' do
    before do
      flipper["my/feature"].disable_rule
      post '/features/my/feature/rule', JSON.dump(rule.value),
        "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].enabled?(actor)).to be_truthy
      expect(flipper["my/feature"].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to eq(rule.value)
    end
  end

  describe 'enable feature with space in name' do
    before do
      flipper["sp ace"].disable_rule
      post '/features/sp%20ace/rule', JSON.dump(rule.value),
        "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].enabled?(actor)).to be_truthy
      expect(flipper["sp ace"].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to eq(rule.value)
    end
  end

  describe 'enable with invalid data' do
    before do
      data = {"blah" => "blah"}
      post '/features/my_feature/rule', JSON.dump(data),
        "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_invalid_response)
    end
  end

  describe 'enable missing feature' do
    before do
      post '/features/my_feature/rule', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'enables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to eq(rule.value)
    end
  end

  describe 'disable missing feature' do
    before do
      delete '/features/my_feature/rule', "CONTENT_TYPE" => "application/json"
    end

    it 'disables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with rule gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rule' }
      expect(gate['value']).to be(nil)
    end
  end
end
