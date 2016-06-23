defmodule ChatServer do 

	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__, [], [name: :the_server])
	end

	def connect(server, sender) do
		GenServer.call(server, {:connect, sender})
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

	def unicast_received(server, globalid) do 
		GenServer.cast(server, {:unicast_received, globalid})
	end

	def unicast_read(server, globalid) do 
		GenServer.cast(server, {:unicast_read, globalid})
	end 

	def clients(server) do 
		GenServer.call(server, {:clients})
	end 

	def silenced(server) do 
		GenServer.call(server, {:silenced})
	end 

    ## CALLBACKS

    def init([]) do
    	{:ok, {0, Map.new , Map.new}}
    end

    def handle_call({:silenced}, _from, {msgid, messages , clients}) do 
    	{:reply, 
    		clients |> Enum.filter(fn {key, value} -> !Enum.empty?(value) end ),
    		{msgid, messages , clients}}
    end 

    def handle_call({:clients}, _from, {msgid, messages , clients}) do 
    	{:reply, Map.keys(clients), {msgid, messages , clients} }
    end 

    def handle_call({:connect, sender}, _from, {msgid, messages , clients}) do

    	Task.async(
    		fn -> Enum.each(
    				Map.keys(clients),
    				fn(client) -> ChatClient.receive_new_peer(client, sender) end) end)

    	{:reply, {:ok, Map.keys(clients)}, {msgid, messages, Map.put(clients, sender, MapSet.new)}}
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
    	
    	ChatClient.receive_message_started(destination, sender)
    	{:noreply, {msgid, messages, clients}}

    end

    def handle_cast({:send_unicast, sender, destination, {localid, message}}, {msgid, messages , clients}) do

    	ChatClient.receive_unicast(destination, {msgid + 1, message})
    	{:noreply, {msgid + 1, Map.put(messages, msgid + 1, {sender, localid, message}), clients}}

	end

	def handle_cast({:send_broadcast, sender, message}, {msgid, messages , clients}) do

		Enum.each(
			MapSet.difference(
				MapSet.new(List.delete(Map.keys(clients), sender)), 
				Map.get(clients, sender)), 
			fn client -> ChatClient.receive_broadcast(client, sender, message) end)

		{:noreply, {msgid, messages , clients}}

	end


	def handle_cast({:unicast_received, globalid}, {msgid, messages , clients}) do

		{sender_id, localid, _} = Map.get(messages, globalid)

		ChatClient.receive_unicast_received(sender_id, localid)

		{:noreply, {msgid, messages , clients}}

	end

	def handle_cast({:unicast_read, globalid}, {msgid, messages, clients}) do

		{sender_id, localid, _} = Map.get(messages, globalid)
		ChatClient.receive_unicast_readed(sender_id, localid)
		{:noreply, {msgid, messages , clients}}

	end


end

