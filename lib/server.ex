defmodule ChatServer do 

	import ChatClient 

	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__, [], [])
	end

	def accept_client(server, sender) do
		GenServer.call(server, {:accept_client, sender})
	end

	def silence(server, sender, to_be_silenced) do 
		GenServer.call(server, {:silence, sender, to_be_silenced})
	end

	def unsilence(server, sender, to_be_unsilenced) do 
		GenServer.call(server, {:unsilence, sender, to_be_unsilenced})
	end 

	def message_started(server, sender, destination) do 
		GenServer.cast(server, {:message_started, sender, destination})
	end

	def send_unicast(server, sender, destination, {localid, message}) do 
		GenServer.cast(server, {:send_unicast, sender, destination, {localid, message}})
	end

	def send_broadcast(server, sender, message) do 
		GenServer.cast(server, {:send_broadcast, sender, message})
	end

	def unicast_received(server, sender, globalid) do 
		GenServer.cast(server, {:unicast_received, sender, globalid})
	end

	def unicast_read(server, sender, globalid) do 
		GenServer.cast(server, {:unicast_read, sender, globalid})
	end 


    ## CALLBACKS

    def init([]) do
    	{:ok, {0, Map.new , Map.new}}
    end

    def handle_call({:accept_client, sender}, _from, {msgid, messages , clients}) do
    	{:reply, :ok, {msgid, messages, Map.put(clients, sender, MapSet.new)}}
    end

    def handle_call({:silence, sender, to_be_silenced}, _from, {msgid, messages, clients}) do
    	{:reply, :ok, {msgid, messages, Map.put(clients, sender, 
    		MapSet.put(Map.get(clients, sender), to_be_silenced))}}
    end

    def handle_call({:unsilence, sender, to_be_unsilenced}, _from, {msgid, messages , clients}) do
    	{:reply, :ok, {msgid, messages, Map.put(clients, sender,
    		MapSet.delete(Map.get(clients, sender), to_be_unsilenced))}}
    end

    def handle_cast({:message_started, sender, destination}, {msgid, messages , clients}) do
    	
    	Client.receive_message_started(destination, sender)
    	{:noreply, {msgid, messages, clients}}

    end

    def handle_cast({:send_unicast, sender, destination, {localid, message}}, {msgid, messages , clients}) do

    	Client.receive_unicast(destination, {msgid + 1, message})
    	{:noreply, {msgid + 1, Map.put(messages, msgid + 1, {sender, localid, message}), clients}}

	end

	def handle_cast({:broadcast, sender, message}, {msgid, messages , clients}) do

		Enum.each(
			MapSet.difference(
				MapSet.new(List.delete(Map.keys(clients), sender)), 
				Map.get(clients, sender)), 
			fn client -> Client.receive_broadcast(client, message) end)

		{:noreply, {msgid, messages , clients}}

	end


	def handle_cast({:unicast_received, sender, globalid}, {msgid, messages , clients}) do

		{sender_id, localid, msg} = Map.get(messages, globalid)

		Client.receive_unicast_received(sender_id, localid)

		{:noreply, {msgid, messages , clients}}

	end

	def handle_cast({:unicast_read, sender, globalid}, {msgid, messages, clients}) do

		{sender_id, localid, msg} = Map.get(messages, globalid)

		Client.receive_unicast_readed(sender_id, localid)

		{:noreply, {msgid, messages , clients}}

	end


end
