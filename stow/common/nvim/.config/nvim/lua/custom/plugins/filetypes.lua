-- Filetype scoping so the correct LSP attaches and YAML servers do not overlap:
--   * docker-compose / compose YAML  -> `yaml.docker-compose`
--       (handled by docker_compose_language_service)
--   * all other YAML stays `yaml`    -> handled by yamlls
--
-- Ansible files are not reliably auto-detected. To get ansiblels, set the
-- filetype explicitly, e.g. `:set filetype=yaml.ansible`, add a modeline, or
-- map your playbook directories yourself. See the package README.
--
-- This file registers filetype rules only; it declares no plugins.

vim.filetype.add {
  pattern = {
    ['.*docker%-compose.*%.ya?ml'] = 'yaml.docker-compose',
    ['.*/compose%.ya?ml'] = 'yaml.docker-compose',
    ['.*/compose%..*%.ya?ml'] = 'yaml.docker-compose',
  },
}

return {}
