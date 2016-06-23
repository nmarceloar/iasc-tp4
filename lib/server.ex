defmodule ChatServer do 

	#use 'ChatClient.exs'
	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__, [], [])
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

    ## CALLBACKS

    def init([]) do
    	{:ok, {0, Map.new , Map.new}}
    end

    def handle_call({:connect, sender}, _from, {msgid, messages , clients}) do
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
    	
    	ChatClient.receive_message_started(destination, sender)
    	{:noreply, {msgid, messages, clients}}

    end

    def handle_cast({:send_unicast, sender, destination, {localid, message}}, {msgid, messages , clients}) do

    	ChatClient.receive_unicast(destination, {msgid + 1, message})
    	{:noreply, {msgid + 1, Map.put(messages, msgid + 1, {sender, localid, message}), clients}}

	end

	def handle_cast({:broadcast, sender, message}, {msgid, messages , clients}) do

		Enum.each(
			MapSet.difference(
				MapSet.new(List.delete(Map.keys(clients), sender)), 
				Map.get(clients, sender)), 
			fn client -> ChatClient.receive_broadcast(client, message) end)

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

	#>>>>>>>>>>>>>CLIENT

defmodule ChatClient do 

	#use 'ChatServer.exs' 
	use GenServer 

    def start_link(server) do
        GenServer.start_link(__MODULE__, server, [])
    end

	def silence(client, to_be_silenced) do
		GenServer.call(client, {:silence, client, to_be_silenced})
	end

	def unsilence(client, to_be_unsilenced) do
		GenServer.call(client, {:unsilence, client, to_be_unsilenced})
	end

	def receive_message_started(client, sender) do
		GenServer.cast(client, {:receive_message_started, sender})
	end

	def send_unicast(client, destination, message) do
		GenServer.cast(client, {:send_unicast, client, destination, message})
	end

	def receive_unicast_received(client, localid) do
		GenServer.cast(client, {:receive_unicast_received, localid})
	end

	def receive_unicast_readed(client, localid) do
		GenServer.cast(client, {:receive_unicast_readed, localid})
	end

	def send_broadcast(client, message) do
		GenServer.cast(client, {:send_broadcast, client, message})
	end

	def receive_unicast(client, {message_id, message}) do
		GenServer.cast(client, {:receive_unicast, client, {message_id, message}})
	end

	def receive_broadcast(client, message) do
		GenServer.cast(client, {:receive_broadcast, message})
	end

	def read_unicast(client, message_id) do
		GenServer.cast(client, {:read_unicast, message_id})
	end

     ## CALLBACKS

    def init(server) do
    	ChatServer.connect(server,self)
        {:ok, {server, Map.new , 0}}
    end

    def handle_call({:silence, client, to_be_silenced}, _from, {server, messages, localid}) do
        ChatServer.silence(server, client, to_be_silenced)
    	{:reply, :ok, {server, messages, localid}}
    end

    def handle_call({:unsilence, client, to_be_unsilenced}, _from, {server, messages, localid}) do
        ChatServer.silence(server, client, to_be_unsilenced)
    	{:reply, :ok, {server, messages, localid}}
    end

    def handle_cast({:receive_message_started, sender}, {server, messages, localid}) do    	
    	IO.puts("#{inspect self} received notification: -- Client: #{inspect sender} started writing a message --")
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:send_unicast, sender, destination, message}, {server, messages, localid}) do
    	ChatServer.message_started(server, sender, destination)
		:timer.sleep(Enum.random(300,500))
		IO.puts("#{inspect self} sent unicast message with localid: #{localid+1}")
		ChatServer.send_unicast(server, sender, destination, {localid + 1, message})
    	{:noreply, {server, Map.put(messages, localid+1, {message, false, false}), localid + 1}}
    end

    def handle_cast({:receive_unicast_received, localid}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver confirmed reception of msg_id: #{localid}  --"
		{msg, _, read} = Map.get(messages, localid)
    	{:noreply, {server, Map.put(messages, localid, {msg, true, read}), localid}}
    end

    def handle_cast({:receive_unicast_readed, localid}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver has read msg_id: #{localid} --"
		{msg, received, _} = Map.get(messages, localid)
    	{:noreply, {server, Map.put(messages, localid, {msg, received, true}), localid}}
    end

    def handle_cast({:send_broadcast, client, message}, {server, messages, localid}) do 
    	ChatServer.send_broadcast(server, client, message)
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:receive_unicast, client, {message_id, message}}, {server, messages, localid}) do
    	IO.puts "#{inspect self} received new unicast msg --> #{message}"
    	ChatServer.unicast_received(server, message_id)
    	:timer.sleep(Enum.random(2000,3000))
    	ChatClient.read_unicast(client, message_id)
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:receive_broadcast, message}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received broadcast -- #{message} --"
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:read_unicast, message_id}, {server, messages, localid}) do
    	ChatServer.unicast_read(server, message_id)
    	{:noreply, {server, messages, localid}}
    end

end 