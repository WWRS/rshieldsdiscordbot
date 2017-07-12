require'bundler/setup'
require'rbnacl/libsodium'

require'ffi'
module Rtricksopus
	def ffi_lib(*names)
		if names == ['opus']
			opus_dir = File.expand_path("..", __FILE__)
			opus_glob = case RUBY_DESCRIPTION
				when /darwin/ then "opus*.dylib"
				when /Windows|(win|mingw)32/ then "opus*.dll"
				else "opus*.so"
			end
			loc = Dir.glob(File.join(opus_dir, opus_glob)).first
			names = [loc]
		end
		super(names)
	end
end
module FFI::Library
	prepend Rtricksopus
end

require'discordrb'
module Rtrickscommandbot
	def execute_command(name, event, arguments, chained = false, check_permissions = true)
		super(name.downcase.to_sym, event, arguments, chained, check_permissions)
	end
	def initialize(attributes = {})
		super(attributes)
		command(@attributes[:help_command], max_args: 1, description: 'Shows a list of all the commands available or displays help for a specific command.', usage: 'help [command name]') do |event, command_name|
			if command_name
				command_name=command_name.downcase.to_sym #ADDED
				command = @commands[command_name.to_sym]
				return "The command `#{command_name}` does not exist!" unless command
				desc = command.attributes[:description] || '*No description available*'
				usage = command.attributes[:usage]
				parameters = command.attributes[:parameters]
				result = "**`#{command_name}`**: #{desc}"
				result += "\nUsage: `#{usage}`" if usage
				if parameters
					result += "\nAccepted Parameters:\n```"
					parameters.each { |p| result += "\n#{p}" }
					result += '```'
				end
				result
			else
				available_commands = @commands.values.reject do |c|
					!c.attributes[:help_available] || !required_roles?(event.user, c.attributes[:required_roles]) || !required_permissions?(event.user, c.attributes[:required_permissions], event.channel)
				end
				case available_commands.length
				when 0..5
					available_commands.reduce "**List of commands:**\n" do |memo, c|
						memo + "**`#{c.name}`**: #{c.attributes[:description] || '*No description available*'}\n"
					end
				when 5..50
					(available_commands.reduce "**List of commands:**\n" do |memo, c|
						memo + "`#{c.name}`, "
					end)[0..-3]
				else
					event.user.pm(available_commands.reduce("**List of commands:**\n") { |m, e| m + "`#{e.name}`, " }[0..-3])
					event.channel.pm? ? '' : 'Sending list in PM!'
				end
			end
		end
	end
end
module Discordrb::Commands
	class CommandBot
		prepend Rtrickscommandbot
	end
end

bot=Discordrb::Commands::CommandBot.new(
	token: ENV['TOKEN'],
	client_id: ENV['APPID'],
	prefix: ['r$','brazilianreal','brazilian real','brl'],
	spaces_allowed: true,
	advanced_functionality: true #required for command chains
)

dir=File.dirname(__FILE__)
voicebot=nil

bot.bucket :voice, limit: 10, time_span: 60, delay: 5

# Commands go here!
#ping
bot.command(:ping,{description:"Pong!",usage:"ping"}){
	"Pong!"
}
#roll/rand/random
bot.command([:roll,:rand,:random],{description:"Gets a random number from 1 to [max], inclusive.",usage:"roll [max]"}){|e,max,*b|
	if max														#If the user sent a max
		if max=="4chan"											#The user tried to roll4chan
			bot.execute_command(:roll4chan,e,b)
		elsif (intmax=max.to_i)>0								#Anything under 1 won't work.
			"Rolled: #{rand(intmax)+1} (#{intmax})"
		else													#Negative input
			"Bad input #{max} . Good inputs are ints above 0."
		end
	else														#The user did not send a max. Default: 100
		"Rolled: #{rand(100)+1} (100)"
	end
}
#flip/coinflip
bot.command([:flip,:coinflip],{description:"Flips a coin",usage:"coinflip"}){
	"Coin flip: #{%w(Heads Tails).sample}"
}
#roll4chan
bot.command([:roll4chan],{description:"Gets a random number from 0000 to 9999, inclusive.",usage:"4chanroll"}){|e,digits|
	if (d=digits.to_i)>0
		"Rolled: #{rand(10**d).to_s.rjust(d,?0)} (4chan, #{d})"
	else
		"Rolled: #{rand(1e4).to_s.rjust(4,?0)} (4chan, 4)"
	end
}
#calc
bot.command([:calc],{description:"Runs simple arithmetic.",usage:"calc [expression]"}){|e,*str|
	fstr=str.join.gsub(/[^0-9+-\/*\(\)\.]/,'')		#Remove all non-math stuff
	fstr=fstr.gsub(/(\d+)/,'\1.to_f') if fstr=~/\//	#Convert to floats if division
	if fstr!=''										#Making sure we don't send nothing
		begin										#In case of invalid expression
			"Calculated: #{eval(fstr).round(9)}"
		rescue Exception => e						#Invalid expression
			"Bad input: #{str.join}"
		end
	else											#Invalid expression
		"Bad input: #{str.join}"
	end
}
#getnum/getnumber/to_f
bot.command([:getnum,:getnumber,:to_f],{description:"Grabs the first number in the input and returns as a float.",usage:"getnumber [expression]"}){|e,*str|
	fstr=str.join.gsub(/[^\d\.]/,' ')	#Replace all non-digits with spaces
	if fstr!=''							#If not empty,
		fstr.to_f						#Return as float.
	else								#If empty,
		0								#Return 0.
	end
}
#stupid
stupidcounter=-1;	#makes sure cycles work.
stupidarray=File.open('stupidarray.txt').readlines
bot.command([:stupid],{description:"Guaranteed to get you a screenshot of stupid. What stupid? RStupid.",usage:"stupid"}){
	stupidcounter = (stupidcounter+1)%stupidarray.size	#Handle cycling
	stupidarray[stupidcounter]							#Return link
}
#join
bot.command(:join, {description:"Join a channel",usage:"join [channel]",bucket: :voice}){|e,c|
	channel = ( c == nil ? e.author.voice_channel : e.channel.server.channels.select{|h|h.name == c && h.voice?}[0] )
	
	if channel != nil
		voicebot = bot.voice_connect(channel, encrypted=true)
	else
		"Invalid channel name."
	end
	return
}
#leave
bot.command(:leave, {description:"Leave the channel",usage:"leave",bucket: :voice}){
	voicebot.destroy
	p voicebot
	return
}
#!
bot.command(:!, {description:"!",usage:"! [channel]",bucket: :voice}){|e,c|
	channel = ( c == nil ? e.author.voice_channel : e.channel.server.channels.select{|h|h.name == c && h.voice?}[0] )
	
	if channel != nil
		voicebot = bot.voice_connect(channel, encrypted=true)
		voicebot.play_file("#{dir}/mgexclamation.mp3")
		voicebot.destroy
		return
	end
	"Invalid channel name."
}
#bot.command(:inviteme,{description:"You can't actually invite me.",usage:"inviteme"}){
#	"Invite me! #{bot.invite_url}"
#}

bot.run
#bot.game="Notepad++"