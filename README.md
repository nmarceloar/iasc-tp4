# IASC - TP4


## Uso 


**Levantar server:**

```
user@userpc:~/iasc-tp4$ iex -S mix 
```

```elixir
iex> ChatServer.Supervisor.start_link()
```

**Comprobar estado de server:**

```elixir
iex> ChatServer.clients(:server)
```

**Probar clientes**

```elixir
iex> {:ok, c1} = ChatClient.connected_to(:server) 
iex> {:ok, c2} = ChatClient.connected_to(:server) 
iex> {:ok, c3} = ChatClient.connected_to(:server) 

iex> ChatClient.peers(c1) 
iex> ChatClient.peers(c2) 
iex> ChatClient.peers(c3) 

iex> ChatClient.send_unicast(c1, c2, :rand.uniform()) 
iex> ChatClient.send_broadcast(c1, :rand.uniform()) 

iex> ChatClient.silence(c1, c2) 
iex> ChatClient.send_broadcast(c1, :rand.uniform()) 

iex> ChatClient.unsilence(c1, c2) 
iex> ChatClient.send_broadcast(c1, :rand.uniform()) 
```

**Comprobar estado de server:**

```elixir
iex> ChatServer.clients(:server)
iex> ChatServer.silenced(:server)
```


## TODO

