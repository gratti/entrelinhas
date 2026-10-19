# Entrelinhas

App simples para criar constância na leitura, acompanhar metas e registrar sessões.

## Configurar o Supabase

1. Abra o projeto Supabase e execute o arquivo [schema.sql](supabase/schema.sql) no SQL Editor.
2. Em Authentication → URL Configuration, defina o Site URL e adicione o endereço publicado do app à lista de Redirect URLs. O cadastro confirma o e-mail e retorna à página atual.
3. Em Authentication → Sign In / Providers, deixe Email habilitado.
4. Publique o site pelo GitHub Pages em Settings → Pages, escolhendo a branch `main` e a pasta `/(root)`.
5. Abra o site publicado, crie uma conta e confirme o cadastro pelo e-mail.

O app usa a Project URL e a Publishable key configuradas em `index.html`. A Publishable key é destinada ao navegador; nunca coloque uma Secret key ou `service_role` no site. As tabelas usam Row Level Security para que cada conta só acesse as próprias leituras e preferências.

## Funcionalidades

- Cadastro e login por e-mail e senha
- Registro de livro, minutos, páginas e data de leitura
- Meta diária sincronizada na conta
- Histórico, sequência de dias e registro rápido de 5 ou 15 minutos
- Dados privados por conta via políticas RLS
