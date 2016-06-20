defmodule ChatClient do 

	import ChatServer 

	use GenServer 

	def silence(client, to_be_silenced) do
		GenServer.call(client, {:silence, to_be_silenced})
	end

	def unsilence(client, to_be_unsilenced) do
		GenServer.call(client, {:unsilence, to_be_unsilenced})
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
		GenServer.cast(client, {:read_unicast, client, message_id})
	end

     ## CALLBACKS

    def handle_call({:silence, to_be_silenced}, _from, {server, messages, localid}) do
    	{:reply, :ok, {msgid, messages, Map.put(clients, sender, MapSet.new)}}
    end

    def handle_call({:unsilence, to_be_unsilenced}, _from, {server, messages, localid}) do
    	{:reply, :ok, {msgid, messages, Map.put(clients, sender, MapSet.new)}}
    end

    def handle_cast({:receive_message_started, sender}, {server, messages, localid}) do    	
    	IO.puts("#{inspect self} received notification: -- Client: #{inspect sender} started writing a message --")
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:send_unicast, sender, destination, message}, {server, messages, localid}) do
    	Server.message_started(server, sender, destination)
		:timer.sleep(random(300,500))
		IO.puts("#{inspect self} sent unicast message with localid: #{localid+1}")
		Server.send_unicast(server, sender, destination, {localid + 1, message})
    	{:noreply, {server, Map.put(messages, localid+1, {msg, false, false}), localid + 1}}
    end

    def handle_cast({:receive_unicast_received, localid}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver confirmed reception of msg_id: #{localid}  --"
		{msg, received, read} = Map.get(messages, localid)
    	{:noreply, {server, Map.put(messages, localid, {msg, true, read}), localid}}
    end

    def handle_cast({:receive_unicast_readed, localid}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver has read msg_id: #{localid} --"
		{msg, received, read} = Map.get(messages, localid)
    	{:noreply, {server, Map.put(messages, localid, {msg, received, true}), localid}}
    end

    def handle_cast({:send_broadcast, client, message}, {server, messages, localid}) do 
    	Server.send_broadcast(server, client, message)
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:receive_unicast, client, {message_id, message}}, {server, messages, localid}) do
    	IO.puts "#{inspect self} received new unicast msg --> #{msg}"
    	Server.unicast_received(server, client, message_id)
    	:timer.sleep(random(2000,3000))
    	Client.read_unicast(client, message_id)
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:receive_broadcast, message}, {server, messages, localid}) do    	
    	IO.puts "#{inspect self} received broadcast -- #{msg} --"
    	{:noreply, {server, messages, localid}}
    end

    def handle_cast({:read_unicast, client, message_id}, {server, messages, localid}) do
    	Server.unicast_read(server, client, message_id)
    	{:noreply, {server, messages, localid}}
    end

end 
