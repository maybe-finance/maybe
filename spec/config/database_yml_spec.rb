require 'rails_helper'
require 'yaml'

RSpec.describe 'database.yml configuration' do
  let(:config) { YAML.load(ERB.new(File.read('config/database.yml')).result) }

  describe 'connection pool size' do
    before do
      ENV['DB_POOL_SIZE'] = nil
      ENV['WEB_CONCURRENCY'] = nil
      ENV['RAILS_MAX_THREADS'] = nil
      ENV['GOOD_JOB_MAX_THREADS'] = nil
    end

    after do
      ENV['DB_POOL_SIZE'] = nil
      ENV['WEB_CONCURRENCY'] = nil
      ENV['RAILS_MAX_THREADS'] = nil
      ENV['GOOD_JOB_MAX_THREADS'] = nil
    end

    it 'calculates default pool size correctly' do
      expect(config['default']['pool']).to eq(8) # (1 * 3) + 5
    end

    it 'uses custom pool size when DB_POOL_SIZE is set' do
      ENV['DB_POOL_SIZE'] = '20'
      expect(YAML.load(ERB.new(File.read('config/database.yml')).result)['default']['pool']).to eq(20)
    end

    it 'calculates pool size based on environment variables' do
      ENV['WEB_CONCURRENCY'] = '2'
      ENV['RAILS_MAX_THREADS'] = '4'
      ENV['GOOD_JOB_MAX_THREADS'] = '6'
      expect(YAML.load(ERB.new(File.read('config/database.yml')).result)['default']['pool']).to eq(14) # (2 * 4) + 6
    end
  end
end
