require_relative '../setup'

class Parlamento
  BASE_URL = "https://dadosabertos.camara.leg.br/api/v2/%s?itens=100".freeze

  def deputados
    @deputados ||= fetch_from_file_or_api('deputados', file_path('deputados'), {
        siglaUf: 'RN'
    })
  end

  def legislaturas
    @legislaturas ||= fetch_from_file_or_api('legislaturas')
  end

  def tipos_proposicao
    @tipos_proposicao ||= fetch_from_file_or_api('referencias/tiposProposicao')
  end

  def blocos
    @blocos ||= fetch_from_file_or_api('blocos')
  end

  def proposicoes
    @deputados ||= fetch_from_file_or_api('proposicoes', file_path('proposicoes'), {
      siglaUfAutor: 'RN',
      ano: 2017
    })
  end

  def detalhes_proposicoes
    if File.exist?(file_path('detalhes_proposicoes'))
      JSON.parse(File.read(file_path('detalhes_proposicoes')))
    else
      results = proposicoes.map do |d|
        proposicao(d['id']) if d.is_a? Hash
      end.compact

      File.open(file_path('detalhes_proposicoes'), 'w+') do |file|
        file.write(results.to_json)
      end

      results
    end
  end

  def proposicao(id)
    fetch_from_file_or_api("proposicoes/#{id}")
  end

  def despesas
    if File.exist?(file_path('detalhes_despesas'))
      JSON.parse(File.read(file_path('detalhes_despesas')))
    else
      results = deputados.map do |d|
        despesa(d['id']) if d.is_a? Hash
      end.compact

      File.open(file_path('detalhes_despesas'), 'w+') do |file|
        file.write(results.to_json)
      end

      results
    end
  end

  def despesa(id)
    fetch_from_file_or_api("deputados/#{id}/despesas", file_path("despesas/#{id}"))
  end

  def detalhes_deputados
    if File.exist?(file_path('detalhes_deputados'))
      JSON.parse(File.read(file_path('detalhes_deputados')))
    else
      results = deputados.map do |d|
        deputado(d['id']) if d.is_a? Hash
      end.compact

      File.open(file_path('detalhes_deputados'), 'w+') do |file|
        file.write(results.to_json)
      end

      results
    end
  end

  def deputado(id)
    fetch_from_file_or_api("deputados/#{id}")
  end

  private

  def fetch_from_file_or_api(resource, filename = file_path(resource), params = {})
    if File.exist?(filename)
      JSON.parse(File.read(filename))
    else
      fetch_and_save(resource, filename, params)
    end
  end

  def file_path(resource)
    File.join(__dir__, '..', 'data', "#{resource}.json")
  end

  def fetch_and_save(resource, filename = file_path(resource), params = {})
    results = fetch(resource, params)
    # results = to_json(fetch(resource))
    File.open(filename, 'w+') do |file|
      file.write(results.to_json)
    end

    results
  end

  def to_json(elements)
    elements.map do |element|
      element.map do |key, value|
        [key, value] if value
      end.compact.to_h
    end.to_json
  end

  def fetch(resource, params = {})
    page = get(format(BASE_URL, resource), params)
    results = page['dados']

    while page['links'] && next_url = page['links'].find { |x| x['rel'] == 'next' } do
      sleep 3
      page = get(next_url['href'], params)
      results << page['dados']
    end
    results
  end

  def get(url, params={})
    puts "******* GET #{url} *****"
    response = RestClient.get(url, params: params, headers: { content_type: :json, accept: :json })
    JSON.parse(response)
  end
end
