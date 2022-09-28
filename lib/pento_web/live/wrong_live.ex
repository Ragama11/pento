defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  # @spec mount(any, any, any) :: {:ok, any}
  def mount(_params, session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 0000)

    {
      :ok,
      assign(
        socket,
        score: 0,
        message: "Guess a number.",
        time: NaiveDateTime.local_now(),
        correct: :rand.uniform(10),
        correct_guess: false,
        user: Pento.Accounts.get_user_by_session_token(session["user_token"]),
        session_id: session["live_socket_id"]
      )
    }
  end

  def handle_event("guess", %{"number" => guess} = data, %{assigns: %{correct: correct}} = socket) do
    IO.inspect(data)
    IO.inspect(correct)

    if Integer.to_string(correct) == guess do
      IO.inspect("correct Guess")
      score = socket.assigns.score + 1

      {
        :noreply,
        assign(
          socket,
          message: "correct guess",
          score: score,
          time: NaiveDateTime.local_now(),
          correct_guess: true
        )
      }
    else
      message = "Your guess: #{guess}. Wrong. Guess again. "
      score = socket.assigns.score - 1

      {
        :noreply,
        assign(
          socket,
          message: message,
          score: score,
          time: NaiveDateTime.local_now()
        )
      }
    end
  end

  def handle_event("restart", _, socket) do
    {
      :noreply,
      socket
      |> assign(correct: :rand.uniform(10))
      |> assign(message: "Restart game")
      |> assign(correct_guess: false)
    }
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)
    {:noreply, assign(socket, time: NaiveDateTime.local_now())}
  end

  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
    <%= @message %>
    </h2>
    <h2>
    <%= for n <- 1..10 do %>
    <a href="#" phx-click="guess" phx-value-number="<%= n %>"><%= n %></a>
    <% end %>
    </h2>

    <h2>
    <%= @message %>
    It's <%= @time %>
    </h2>
    <%=  if @correct_guess do %>
    <button type="button" phx-click="restart" class="btn-primary btn">Reset</button>
    <% end %>
    <pre>
    <%= @user.username %>
    <%= @session_id %>
    </pre>
    """
  end

  def time() do
    DateTime.utc_now() |> to_string
  end
end
