# Charger API

Uma API Rails para gerenciamento de dívidas com processamento assíncrono de arquivos CSV.

## Funcionalidades

- Importação de dívidas via arquivo CSV
- Processamento assíncrono com Sidekiq
- API RESTful para gerenciamento de dívidas
- Validações e tratamento de erros

## Tecnologias

- Ruby 3.3.5
- Rails 7.1.5
- PostgreSQL
- Sidekiq (processamento assíncrono)
- Redis (armazenamento de jobs)
- RSpec (testes)

## Configuração

### Pré-requisitos

- Ruby 3.3.5
- PostgreSQL
- Redis

### Instalação

1. Clone o repositório:
```bash
git clone <repository-url>
cd charger-api
```

2. Instale as dependências:
```bash
bundle install
```

3. Configure o banco de dados:
```bash
rails db:create
rails db:migrate
```

4. Configure o Redis (certifique-se de que está rodando):
```bash
redis-server
```

## Uso

### Iniciando a aplicação

1. Inicie o servidor Rails:
```bash
rails server
```

2. Inicie o Sidekiq (em outro terminal):
```bash
bundle exec sidekiq
```

3. Acesse a interface web do Sidekiq (opcional):
```bash
bundle exec sidekiq-web
```

### Importando arquivos CSV

Faça uma requisição POST para `/api/v1/debts/import_debts_csv` com um arquivo CSV:

```bash
curl -X POST \
  http://localhost:3000/api/v1/debts/import_debts_csv \
  -F "file=@debts.csv"
```

Formato do CSV:
```csv
name,government_id,email,debt_amount,debt_due_date,debt_id,status
João Silva,12345678901,joao@example.com,1000.50,2024-12-31,DEBT001,pending
Maria Santos,98765432100,maria@example.com,2500.75,2024-11-30,DEBT002,pending
```

### Processamento Assíncrono

O arquivo CSV é processado de forma assíncrona:

1. O arquivo é salvo temporariamente
2. Um job `LoadDebtsJob` é enfileirado no Sidekiq
3. O job processa o CSV e cria os registros de dívida
4. O arquivo temporário é removido após o processamento

## Testes

Execute os testes:
```bash
bundle exec rspec
```

## Estrutura do Projeto

```
app/
├── controllers/
│   └── api/v1/
│       └── debts_controller.rb
├── jobs/
│   └── load_debts_job.rb
├── models/
│   └── debt.rb
└── services/
    └── debts_csv_import_service.rb

config/
├── sidekiq.yml
└── initializers/
    └── sidekiq.rb

spec/
├── jobs/
│   └── load_debts_job_spec.rb
├── requests/
│   └── api/v1/
│       └── debts_controller_spec.rb
└── services/
    └── debts_csv_import_service_spec.rb
```

## Configuração do Sidekiq

O Sidekiq está configurado com:

- **Concurrency**: 5 workers (desenvolvimento: 2, produção: 10)
- **Queues**: default, mailers, active_storage, debts_import
- **Redis**: localhost:6379/0 (configurável via REDIS_URL)

## Monitoramento

Para monitorar os jobs do Sidekiq:

1. Interface web: `bundle exec sidekiq-web`
2. Logs: `tail -f log/sidekiq.log`
3. Redis CLI: `redis-cli`

## Desenvolvimento

### Adicionando novos jobs

1. Crie o job:
```bash
rails generate job MyJob
```

2. Configure a queue:
```ruby
class MyJob < ApplicationJob
  queue_as :my_queue
end
```

3. Enfileire o job:
```ruby
MyJob.perform_later(args)
```

### Configuração de ambiente

Para diferentes ambientes, ajuste o `config/sidekiq.yml`:

```yaml
development:
  :concurrency: 2

production:
  :concurrency: 10
  :redis:
    :url: <%= ENV['REDIS_URL'] %>
```

## Troubleshooting

### Sidekiq não inicia
- Verifique se o Redis está rodando: `redis-cli ping`
- Verifique as configurações em `config/sidekiq.yml`

### Jobs não processam
- Verifique os logs: `tail -f log/sidekiq.log`
- Verifique se o Sidekiq está rodando: `ps aux | grep sidekiq`

### Erro de conexão com Redis
- Verifique se o Redis está rodando
- Verifique a URL do Redis em `config/initializers/sidekiq.rb`
