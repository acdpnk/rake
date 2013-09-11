defmodule ApplicationRouter do
  use Dynamo.Router

  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn.fetch([:cookies, :params])
  end

  # It is common to break your Dynamo into many
  # routers, forwarding the requests between them:
  # forward "/posts", to: PostsRouter

  get "/" do
    config_path="~/rake/.config"
    case config_path |> Path.expand |> File.read do
        {:ok, config_json} ->
            case JSEX.decode config_json, [{:labels, :atom}] do
                {:ok, config} ->
                    callback_url = config[:callback_url]
                    client_id = config[:client_id]
                _ ->
                    :error
            end
        _ ->
            callback_url="error"
            client_id="error"
            :error
    end
    conn = conn.assign(:client_id, client_id)
    conn = conn.assign(:callback_url, callback_url)
    conn = conn.assign(:title, "authorize rakeapp")
    render conn, "index.html"
  end

  forward "/welcome", to: WelcomeRouter

  forward "/rss", to: FeedRouter

  forward "/opts", to: OptionsRouter
end
