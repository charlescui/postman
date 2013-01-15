require_relative '../lib/postman'

include Postman::App::Model


u1 = User.new(
        :id => '1234567890',
        :name => "pman1",
        :ttl => 60,
        :private_key => "22fe394"
        )
u2 = User.new(
        :id => '0987654321',
        :name => "pman2",
        :ttl => 60,
        :private_key => "22fe394"
        )

u3 = User.new(
        :id => '09ngdfsd4321',
        :name => "pman3",
        :ttl => 60,
        :private_key => "22fe394"
        )

[u1,u2,u3].each    do |u|
	u.user_credentials
    u.save if !u.exists
end