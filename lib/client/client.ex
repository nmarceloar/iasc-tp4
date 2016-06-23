defmodule ChatClient do 

	use GenServer 

	def start_link() do 
		GenServer.start_link(__MODULE__,[], []) 
	end

   	def silence(client, to_be_silenced) do
		GenServer.call(client, {:silence, to_be_silenced})
	end

	def unsilence(client, to_be_unsilenced) do
		GenServer.call(client, {:unsilence, to_be_unsilenced})
	end

	def receive_message_started(client, message_sender) do
		GenServer.cast(client, {:receive_message_started, message_sender})
	end

	def send_unicast(client, destination, message) do
		GenServer.cast(client, {:send_unicast, destination, message})
	end

	def receive_unicast_received(client, localid) do
		GenServer.cast(client, {:receive_unicast_received, localid})
	end

	def receive_unicast_readed(client, localid) do
		GenServer.cast(client, {:receive_unicast_readed, localid})
	end

    def receive_new_peer(client, peer) do 
        GenServer.cast(client, {:receive_new_peer, peer})
    end 

    def peers(client) do
        GenServer.call(client, {:peers})
    end

	def send_broadcast(client, message) do
		GenServer.cast(client, {:send_broadcast, message})
	end

	def receive_unicast(client, {message_id, message}) do
		GenServer.cast(client, {:receive_unicast, client, {message_id, message}})
	end

	def receive_broadcast(client, sender, message) do
		GenServer.cast(client, {:receive_broadcast, sender, message})
	end

	def read_unicast(client, message_id) do
		GenServer.cast(client, {:read_unicast, message_id})
	end

    defp random(min, max) do 
        Kernel.trunc(min + (:rand.uniform*(max - min)))
    end 

    ## CALLBACKS

    def init([]) do

        {:ok, hostname} = :inet.gethostname()
        default_server = {:the_server, String.to_atom("server@" <> to_string(hostname))}
        
    	{:ok, peers} = ChatServer.connect(default_server, self)

        {:ok, {default_server, peers, Map.new , 0}}

    end

    def handle_call({:silence, to_be_silenced}, _from, {server, peers, messages, localid}) do
        ChatServer.silence(server, self(), to_be_silenced)
    	{:reply, :ok, {server, peers, messages, localid}}
    end

    def handle_call({:peers}, _from, {server, peers, messages, localid}) do
        {:reply, peers, {server, peers, messages, localid}}
    end


    def handle_call({:unsilence, to_be_unsilenced}, _from, {server, peers, messages, localid}) do
        ChatServer.unsilence(server, self, to_be_unsilenced)
    	{:reply, :ok, {server, peers, messages, localid}}
    end

    def handle_cast({:receive_message_started, message_sender}, {server, peers, messages, localid}) do    	
    	IO.puts("#{inspect self} received notification: -- Client: #{inspect message_sender} started writing a message --")
    	{:noreply, {server, peers, messages, localid}}
    end

    def handle_cast({:receive_new_peer, peer}, {server, peers, messages, localid}) do      
        IO.puts("#{inspect self} received notification: -- New peer: #{inspect peer}  --")
        {:noreply, {server, [peer|peers], messages, localid}}
    end

    def handle_cast({:send_unicast, destination, message}, {server, peers, messages, localid}) do
    	ChatServer.message_started(server, self, destination)
		:timer.sleep(random(300,500))
		IO.puts("#{inspect self} sent unicast message with localid: #{localid+1} to #{inspect destination}")
		ChatServer.send_unicast(server, self, destination, {localid + 1, message})
    	{:noreply, {server, peers, Map.put(messages, localid+1, {message, false, false}), localid + 1}}
    end

    def handle_cast({:receive_unicast_received, localid}, {server, peers, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver confirmed reception of msg_id: #{localid}  --"
		{msg, _, read} = Map.get(messages, localid)
    	{:noreply, {server, peers, Map.put(messages, localid, {msg, true, read}), localid}}
    end

    def handle_cast({:receive_unicast_readed, localid}, {server, peers, messages, localid}) do    	
    	IO.puts "#{inspect self} received notification: -- Receiver has read msg_id: #{localid} --"
		{msg, received, _} = Map.get(messages, localid)
    	{:noreply, {server, peers, Map.put(messages, localid, {msg, received, true}), localid}}
    end

    def handle_cast({:send_broadcast, message}, {server, peers, messages, localid}) do 
    	ChatServer.send_broadcast(server, self, message)
    	{:noreply, {server, peers, messages, localid}}
    end

    def handle_cast({:receive_unicast, client, {message_id, message}}, {server, peers, messages, localid}) do
    	IO.puts "#{inspect self} received new unicast msg --> #{message}"
    	ChatServer.unicast_received(server, message_id)
    	:timer.sleep(random(2000,3000))
    	ChatClient.read_unicast(client, message_id)
    	{:noreply, {server, peers, messages, localid}}
    end

    def handle_cast({:receive_broadcast, sender, message}, {server, peers, messages, localid}) do    	
    	IO.puts "#{inspect self} received broadcast -- #{message} -- from #{inspect sender}"
    	{:noreply, {server, peers, messages, localid}}
    end

    def handle_cast({:read_unicast, message_id}, {server, peers, messages, localid}) do
    	ChatServer.unicast_read(server, message_id)
    	{:noreply, {server, peers, messages, localid}}
    end

end 