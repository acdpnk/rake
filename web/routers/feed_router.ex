defmodule FeedRouter do
  use Dynamo.Router

  def xml_quote(str) do
    str |> to_string |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;") |> String.replace("\"", "&quot;")
  end

  defp parse(url, readability_key) do
    unless url == nil do
        line = 'https://readability.com/api/content/v1/parser?token=' ++ to_char_list(readability_key) ++ '&url=' ++ to_char_list(url)
        IO.inspect(is_list line)
        IO.inspect line
        case :httpc.request line do
            {:ok, {{_,_,'OK'}, _, resp}} ->
                case JSEX.decode to_string(resp), [{:labels, :atom}] do
                    {:ok, parsed}   -> {:ok, parsed[:title], parsed[:content]}
                    _ -> {}
                end
            _ -> {}

        end
      end
  end

  def parse_multiple(itemlist, readability_key) do
      :inets.start
      :ssl.start
      items = Parallel.map itemlist, fn item ->
          case parse item[:link], readability_key do
              {:ok, title, content} ->
                  [id: item[:id], title: xml_quote(title), original_post: xml_quote(item[:original_post]), summary: xml_quote("<hr><h1>" <> title <> "</h1>" <> content), link: xml_quote(item[:link]), clients: item[:clients]]
              _ -> []
          end
      end
      case items do
        :error -> :error
        list   -> {:ok, list}
      end
  end

  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn.fetch([:params])
  end

  get "/" do
      config_path="~/rake/.config"
      case config_path |> Path.expand |> File.read do
          {:ok, config_json} ->
              case JSEX.decode config_json, [{:labels, :atom}] do
                  {:ok, config} ->
                      callback_url = config[:callback_url]
                      readability_key = config[:readability_key]
                  _ ->
                      :error
              end
          _ ->
              :error
      end

    HTTPotion.start
    token = conn.params[:token]
    resp = HTTPotion.get "https://alpha-api.app.net/stream/0/posts/stream?count=50&access_token=" <> token
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

        url = (Enum.at post[:entities][:links], 0)[:url]

        item = item ++ [link: url]

        item = item ++ [id: post[:id]]

        original_post = "<strong>" <> post[:user][:username] <> "</strong>: " <> post[:html]
        item = item ++ [original_post: original_post]

        summary = ""
        item = item ++ [summary: summary]

        clients = []

        if conn.params[:alpha] == "1" do
          alpha_link = post[:canonical_url]
          clients = clients ++ [[name: "alpha", link: alpha_link]]
        end

        if conn.params[:felix] == "1" do
          felix_link = "felix://post/" <> post[:id]
          clients = clients ++ [[name: "felix", link: felix_link]]
        end

        if conn.params[:riposte] == "1" do
          riposte_link = "riposte://x-callback-url/showPostDetail?postID=" <> post[:id]
          clients = clients ++ [[name: "riposte", link: riposte_link]]
        end

        if conn.params[:happy] == "1" do
          happy_link = "happy://post?postId=" <> post[:id]
          clients = clients ++ [[name: "hAppy", link: happy_link]]
        end

        item = item ++ [clients: clients]

        cond do
          url != "" -> item
          true -> nil
        end
        end

    {:ok, items} = parse_multiple items, readability_key

    conn = conn.assign(:items, items)
    conn = conn.assign(:channel_title, channel_title)
    conn = conn.assign(:channel_link, channel_link)
    conn = conn.assign(:channel_summary, channel_summary)
    render conn, "rss.xml"
  end
end
