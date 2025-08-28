# Testes da API de Débitos

Este diretório contém todos os testes da aplicação, organizados por tipo e funcionalidade.

## Estrutura dos Testes

```
spec/
├── models/                    # Testes unitários dos modelos
│   └── debt_spec.rb
├── services/                  # Testes unitários dos services
│   └── debts_csv_import_service_spec.rb
├── requests/                  # Testes de integração (controllers)
│   └── api/v1/debts_controller_spec.rb
├── features/                  # Testes de feature (fluxos completos)
│   └── debts_import_spec.rb
├── factories/                 # Factories para criar dados de teste
│   └── debts.rb
└── support/                   # Configurações de suporte
    └── factory_bot.rb
```

## Como Executar os Testes

### Instalar dependências
```bash
bundle install
```

### Executar todos os testes
```bash
bundle exec rspec
```

### Executar testes específicos
```bash
# Apenas testes de modelo
bundle exec rspec spec/models/

# Apenas testes de service
bundle exec rspec spec/services/

# Apenas testes de controller
bundle exec rspec spec/requests/

# Apenas testes de feature
bundle exec rspec spec/features/

# Teste específico
bundle exec rspec spec/models/debt_spec.rb
```

### Executar com detalhes
```bash
bundle exec rspec --format documentation
```

## Tipos de Teste

### 1. Testes Unitários (Models)
- Testam a lógica dos modelos
- Validam scopes e validações
- Testam factories

### 2. Testes Unitários (Services)
- Testam a lógica de negócio
- Validam processamento de arquivos
- Testam geração de UUIDs

### 3. Testes de Integração (Controllers)
- Testam endpoints da API
- Validam respostas HTTP
- Testam tratamento de erros

### 4. Testes de Feature
- Testam fluxos completos
- Validam integração entre componentes
- Testam cenários reais de uso

## Cobertura de Testes

Os testes cobrem:

- ✅ Modelo Debt (scopes, validações)
- ✅ Service de importação CSV
- ✅ Controller de débitos
- ✅ Fluxo completo de importação
- ✅ Tratamento de erros
- ✅ Geração de UUIDs
- ✅ Criação de diretórios
- ✅ Salvamento de arquivos

## Dados de Teste

Utilizamos:
- **FactoryBot**: Para criar dados de teste
- **Faker**: Para gerar dados realistas
- **Tempfile**: Para simular uploads de arquivo
- **DatabaseCleaner**: Para limpar o banco entre testes
