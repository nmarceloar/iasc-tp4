defmodule ServerTest do
  use ExUnit.Case

  test "otp implemented server" do

    {:ok, server} = ServerOTP.start_link()

    assert ServerOTP.get(server, "/document") == {:ok, :not_found}

    ServerOTP.post(server, "/document", "hello world")

    assert ServerOTP.get(server, "/document") == {:ok, "hello world"}

    ServerOTP.delete(server, "/document")

    assert ServerOTP.get(server, "/document") == {:ok, :not_found}
  end

  test "otpless implemented server" do

    {:ok, server} = Server.start_link()

    assert Server.get(server, "/document") == {:ok, :not_found}

    Server.post(server, "/document", "hello world")

    assert Server.get(server, "/document") == {:ok, "hello world"}

    Server.delete(server, "/document")

    assert Server.get(server, "/document") == {:ok, :not_found}
  end  
end