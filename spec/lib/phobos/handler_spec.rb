# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Phobos::Handler do
  class TestIncludeHandler
    include Phobos::Handler
  end

  it 'includes default ".start"' do
    expect { TestIncludeHandler.start(double('Kafka::Client')) }
      .to_not raise_error
  end

  it 'includes default ".stop"' do
    expect { TestIncludeHandler.stop }.to_not raise_error
  end

  it 'includes default "#around_consume"' do
    expect { |block| TestIncludeHandler.new.around_consume('payload', {}, &block) }
      .to yield_with_args('payload', {})
  end

  describe '#consume' do
    it 'raises NotImplementedError' do
      expect { TestIncludeHandler.new.consume('', {}) }
        .to raise_error NotImplementedError
    end
  end
end
