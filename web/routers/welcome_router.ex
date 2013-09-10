defmodule WelcomeRouter do
    use Dynamo.Router

    prepare do
        conn.fetch([:params])
    end

    get "/" do
        :inets.start()
        :ssl.start()

        config_path="~/rake/.config"
        case config_path |> Path.expand |> File.read do
            {:ok, config_json} ->
                case JSEX.decode config_json, [{:labels, :atom}] do
                    {:ok, config} ->
                        client_id = config[:client_id]
                        client_secret = config[:client_secret]
                        callback_url = config[:callback_url]
                    _ ->
                        :error
                end
            _ ->
                :error
        end
        code = conn.params[:code]
        body = to_char_list "client_id=" <> client_id <> "&client_secret=" <> client_secret <> "&grant_type=authorization_code&redirect_uri=" <> callback_url <> "/welcome&code=" <> code

        url = 'https://account.app.net/oauth/access_token'




        case :httpc.request(:'post', {url, [], 'application/x-www-form-urlencoded', body}, [], []) do
            {:ok, {{a,b,'OK'}, _, resp}} ->
                resp = to_string resp
                token = JSEX.decode!(resp, [{:labels, :atom}])[:access_token]
            {:ok, {{a,b,err}, _, resp}} ->
                token = err
        end



        feed_url = callback_url <> "/rss?alpha=1&token=" <> token
        conn = conn.assign(:feed_url, feed_url)
        conn = conn.assign(:title, "foo")
        render conn, "welcome.html"
    end
end
