# IASC - TP4


## Uso 


**Levantar server node en una terminal:** 
```
user@userpc:~/iasc-tp4$ iex --sname server --cookie tp4 -S mix 
```

**Comprobar estado de server:**

```elixir
iex(server@userpc)> ChatServer.clients(:the_server)
```

**En otra terminal(ó en varias), levantar un nodo cliente y usar módulo ChatClient para crear clientes y probar mensajes a server. Ej:**

```
user@userpc:~/iasc-tp4$ iex --sname c1 --cookie tp4 -S mix 
```

```elixir
iex(c1@userpc)> c1 = ChatClient.connected_to(server) 
iex(c1@userpc)> c2 = ChatClient.connected_to(server) 
iex(c1@userpc)> c3 = ChatClient.connected_to(server) 

iex(c1@userpc)> ChatClient.peers(c1) 
iex(c1@userpc)> ChatClient.peers(c2) 
iex(c1@userpc)> ChatClient.peers(c3) 

iex(c1@userpc)> ChatClient.send_unicast(c1, c2,  :rand.uniform()) 
iex(c1@userpc)> ChatClient.send_broadcast(c1, :rand.uniform()) 

iex(c1@userpc)> ChatClient.silence(c1, c2) 
iex(c1@userpc)> ChatClient.send_broadcast(c1, :rand.uniform()) 

iex(c1@userpc)> ChatClient.unsilence(c1, c2) 
iex(c1@userpc)> ChatClient.send_broadcast(c1, :rand.uniform()) 
```

**Comprobar estado de server:**

```elixir
iex(server@userpc)> ChatServer.clients(:the_server)
iex(server@userpc)> ChatServer.silenced(:the_server)
```


## ToDo

 