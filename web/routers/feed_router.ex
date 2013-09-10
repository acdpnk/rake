defmodule FeedRouter do
  use Dynamo.Router

  def xml_quote(str) do
    str |> to_string |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;") |> String.replace("\"", "&quot;")
  end

  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn.fetch([:params])
  end

  get "/" do
      config_path="/home/rakeapp/rake/.config"
      case File.read config_path do
          {:ok, config_json} ->
              case JSEX.decode config_json, [{:labels, :atom}] do
                  {:ok, config} ->
                      callback_url = config[:callback_url]
                  _ ->
                      :error
              end
          _ ->
              :error
      end

    HTTPotion.start
    token = conn.params[:token]
    resp = HTTPotion.get "https://alpha-api.app.net/stream/0/posts/stream?count=20&access_token=" <> token
    posts = JSEX.decode!(resp.body, [{:labels, :atom}])[:data]

    resp = HTTPotion.get "https://alpha-api.app.net/stream/0/users/me?access_token=" <> token
    user = JSEX.decode!(resp.body, [{:labels, :atom}])[:data]
    username = user[:username]
    userlink = user[:canonical_url]

    channel_title = "links from @" <> username <> "\'s stream."
    channel_title = xml_quote channel_title

    channel_link = userlink

    channel_summary = "all the links from @" <> username <> "\'s stream on <a href=\"http://app.net/join\">app.net</a>. via <a href=\"" <> callback_url <> "\">rakeapp</a>."
    channel_summary = xml_quote channel_summary

    items = lc post inlist posts do
        item = []

        title = "via @" <> post[:user][:username]
        title = xml_quote title
        item = item ++ [title: title]

        url = (Enum.at post[:entities][:links], 0)[:url]
        url = xml_quote url
        item = item ++ [link: url]

        summary = post[:html]

        clients = []
        if conn.params[:felix] do
          felix_link = "felix://post/" <> post[:id]
          clients = clients ++ [[name: "felix", link: felix_link]]
        end

        if conn.params[:alpha] do
          alpha_link = post[:canonical_url]
          clients = clients ++ [[name: "alpha", link: alpha_link]]
        end

        item = item ++ [clients: clients]

        summary = xml_quote summary
        item = item ++ [summary: summary]

        cond do
          url != "" -> item
          true -> nil
        end
    end

    conn = conn.assign(:items, items)
    conn = conn.assign(:channel_title, channel_title)
    conn = conn.assign(:channel_link, channel_link)
    conn = conn.assign(:channel_summary, channel_summary)
    render conn, "rss.xml"
  end
end
