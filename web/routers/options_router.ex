defmodule OptionsRouter do
    use Dynamo.Router

    prepare do
        conn.fetch [:params]
    end

    get "/" do
        conn = conn.assign :callback_url, conn.params[:callback_url]
        conn = conn.assign :token, conn.params[:token]
        conn = conn.assign :alpha, conn.params[:alpha]
        conn = conn.assign :felix, conn.params[:felix]
        conn = conn.assign :happy, conn.params[:happy]
        conn = conn.assign :riposte, conn.params[:riposte]

        render conn, "welcome.html"
    end

end