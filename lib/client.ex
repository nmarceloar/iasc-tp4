defmodule ChatClient do 

	import ChatServer 

	use GenServer 

	def send_unicast(client) do 
	end 

	def send_broadcast(client, message) do
	end

	def receive_unicast(client, server, {msgid, sender, message}) do 
	end 

	def receive_broadcast(client, server, {sender, message}) do 
	end 

	def message_started(client, server, sender) do 
	end 

end 