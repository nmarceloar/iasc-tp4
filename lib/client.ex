defmodule ChatClient do 

	import ChatServer 

	use GenServer 

	def silence(client, server, to_be_silenced) do
		GenServer.call(server, {:silence, client, to_be_silenced})
	end

	def unsilence(client, to_be_unsilenced) do
		GenServer.call(server, {:unsilence, client, to_be_unsilenced})
	end

	def receive_message_started(client, server, sender) do
		
	end

	def send_unicast(client, destination, message) do
		
	end

	def receive_unicast_received(client, server, localid) do
		
	end

	def receive_unicast_readed(client, server, localid) do
		
	end

	def send_broadcast(client, message) do
		
	end

	def receive_unicast(client, server, {message_id, message}) do
		
	end

	def receive_broadcast(client, server, message) do
		
	end

	def read_unicast(client, message_id) do
		
	end

end 
