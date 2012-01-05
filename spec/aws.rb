class AWS

  def self.root
    rails_root = (Rails.version < "2.1.2") ? RAILS_ROOT : Rails.root
    YAML::load(IO.read(File.join(rails_root, 'config', 'aws.yml')))
  end

  def self.key
    AWS.root[RAILS_ENV]['access_key_id']
  end

  def self.secret
    AWS.root[RAILS_ENV]['secret_access_key']
  end
end


