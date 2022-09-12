require 'spec_helper'

describe Http do
  it 'uses a proxy if one is configured' do
    proxy_url = 'socks5h://localhost:9050'
    Conf.instance.config['http_proxy'] = proxy_url

    http = Http.new('http://localhost/something')

    expect(http.request.options[:proxy]).to eql(proxy_url)

    Conf.instance.reload!
  end
end

