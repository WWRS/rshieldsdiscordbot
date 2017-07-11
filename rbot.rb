::RBNACL_LIBSODIUM_GEM_LIB_PATH = "libsodium.dll"
require_relative'discordrb'

tokentxt = File.open('C:/token.txt').gets.chomp

bot=Discordrb::Commands::CommandBot.new(
	token: tokentxt,
	client_id: 285649587686080523,
	prefix: ['r$','brazilianreal','brazilian real','brl'],
	spaces_allowed: true,
	advanced_functionality: true #required for command chains
)

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
			"Rolled (#{intmax}): #{rand(intmax)+1}"
		else													#Negative input
			"Bad input #{max} . Good inputs are ints above 0."
		end
	else														#The user did not send a max. Default: 100
		"Rolled (100): #{rand(100)+1}"
	end
}
#flip/coinflip
bot.command([:flip,:coinflip],{description:"Flips a coin",usage:"coinflip"}){
	"Coin flip: #{%w(Heads Tails).sample}"
}
#roll4chan
bot.command([:roll4chan],{description:"Gets a random number from 0000 to 9999, inclusive.",usage:"4chanroll"}){|e,digits|
	if (d=digits.to_i)>0
		"Rolled (4chan, #{d}): #{rand(10**d).to_s.rjust(d,?0)}"
	else
		"Rolled (4chan, 4): #{rand(1e4).to_s.rjust(4,?0)}"
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
	fstr=str.join.gsub(/\D/,' ')	#Replace all non-digits with spaces
	if fstr!=''						#If not empty,
		fstr.to_f					#Return as float.
	else							#If empty,
		0							#Return 0.
	end
}
#stupid
stupidcounter=-1;	#makes sure cycles work.
	#Change this array.
stupidarray=%w(http://image.prntscr.com/image/160a60a9e3454c4bbb08ddd00aac980f.png
		http://image.prntscr.com/image/b871f15d6f1e4e63b05b81d2d3d13fdc.png
		http://i.imgur.com/pS698mS.png
		http://image.prntscr.com/image/53999e3b330d4103ac46d9b2ebecc6b1.png
		http://i.imgur.com/W8mYJ73.png
		http://i.imgur.com/FMLBKey.png
		http://i.imgur.com/iKVK8Hx.png)
bot.command([:stupid],{description:"Guaranteed to get you a screenshot of stupid. What stupid? RStupid.",usage:"stupid"}){
	stupidcounter = (stupidcounter+1)%stupidarray.size	#Handle cycling
	stupidarray[stupidcounter]							#Return link
}
#!
bot.command(:!, {description:"!",usage:"! [channel]"}){|e,chan|
	channel = e.channel.server.channels.select{|h|h.name==chan&&h.voice?}[0]
	if channel!=nil
		voicebot = bot.voice_connect(channel, encrypted=true)
		voicebot.play_file("mgexclamation.mp3")
		bot.voice_destroy(channel)
	else
		"Invalid channel name."
	end
}
bot.command(:inviteme,{description:"You can't actually invite me.",usage:"inviteme"}){
	"Invite me! #{bot.invite_url}"
}

bot.run
#bot.game="Notepad++"