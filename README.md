# Meu Financeiro

Aplicação web responsiva para controle pessoal de salário, rendas adicionais, despesas mensais, histórico e relatórios. O frontend usa HTML, CSS e JavaScript puro. O Supabase fornece autenticação, banco PostgreSQL e isolamento de dados com Row Level Security (RLS).

## Rodar localmente

1. Crie um projeto no [Supabase](https://supabase.com/).
2. No SQL Editor do projeto, execute o arquivo `database/schema.sql`.
3. Em **Project Settings → API**, copie a Project URL e a chave pública `anon` (ou `publishable`). Edite `js/config.js` e preencha `supabaseUrl` e `supabaseAnonKey`.
4. Sirva a pasta por um servidor web local, por exemplo `python -m http.server 8000`, e abra `http://localhost:8000`. A página não deve ser aberta como `file://`, porque autenticação e redirecionamentos precisam de uma origem web.
5. No painel Supabase, em **Authentication → URL Configuration**, adicione a URL local e a URL de publicação em **Redirect URLs**. Configure SMTP para e-mails de confirmação e recuperação em produção.

Nunca use a chave `service_role` no navegador. A chave pública é apropriada no frontend porque todas as tabelas têm RLS habilitado e as políticas conferem `auth.uid()` no banco.

## O que está incluído

- Cadastro, login, sessão persistente, confirmação por e-mail, recuperação e atualização de senha.
- Dashboard mensal com salário, extras, gastos, saldo, visualização de categorias e comparação visual de renda e gastos.
- CRUD de salário, renda adicional e despesas, com validações, confirmação para excluir, pesquisa, filtros e ordenação.
- Navegação por mês e ano; os registros permanecem no Supabase ao trocar de mês ou dispositivo.
- Relatórios mensais, por intervalo ou de todo o histórico; exportação CSV e impressão para salvar como PDF.
- SQL de tabelas, índices, constraints, timestamps, perfil criado no cadastro e políticas RLS por usuário.

## Modelo e segurança

O SQL cria `profiles`, `monthly_income`, `additional_income` e `expenses`. Os valores são `numeric(14,2)`, salários são únicos por usuário e mês, e todas as tabelas têm políticas RLS. Dados financeiros usam o `user_id` da sessão; a interface também filtra pelo identificador autenticado. O trigger de criação do perfil é executado no banco.

## Configurações manuais no Supabase

- Executar `database/schema.sql` no SQL Editor.
- Preencher URL do projeto e chave pública em `js/config.js`.
- Configurar Site URL e Redirect URLs para cada ambiente em Authentication → URL Configuration.
- Definir se confirmação de e-mail deve estar ativa. Com confirmação ativada, cada pessoa confirma o endereço antes do primeiro login.
- Configurar um provedor SMTP confiável para entrega de confirmação e recuperação antes de publicar.
- Publicar esta pasta em um host estático com HTTPS. Atualizar as URLs de redirecionamento para o domínio de produção.

Não existe acesso administrativo ou chave secreta no frontend. Revise as políticas no painel após aplicar o script; nunca desative RLS para corrigir erros de integração.
