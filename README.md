## Projeto DHCP/DNS Integrado em Linux
## Projeto_Diogo_Pascoal_GRSC_0925

Este projecto apresenta scripts de linux para configuração e integração dos serviços **DHCP** (Dynamic Host Configuration Protocol) e **DNS** (Domain Name System).

---

### Demonstração Visual

<div align="center">
    <img src="https://github.com/user-attachments/assets/4596ee1f-7e6b-4f74-998e-ea1398fd0651" alt="Vídeo demonstrando Kea DHCP e Bind DNS em ação" width="450"/>
    <br>
    <p><b>Script DHCP (Kea) + DNS (Bind)</b></p>
</div>

---

## Objetivos do Projeto

O principal objetivo é implementar o **Dynamic DNS (DDNS)**, garantindo a sincronização automática e em tempo real entre a concessão de IPs e o registro de nomes de host.

* **Automação:** Gerenciamento automatizado de endereços IP via DHCP.
* **Resolução:** Configuração robusta do DNS (BIND) para resolver nomes de rede.
* **Sincronização:** Implementação do DDNS para atualização imediata dos registros de nomes.

---

## Instruções de Uso

Siga estas instruções para a correta implementação e teste do ambiente.

### 1. Configuração de Rede (VM)

É fundamental que o servidor Linux utilizado para rodar os serviços tenha a seguinte configuração de rede:

* O servidor deve possuir **dois adaptadores de rede**:
    * Um em modo **NAT** (Para acesso à Internet, atualizações e downloads).
    * Outro em modo **LAN Segment** (Para comunicação direta e isolada com as máquinas clientes).

### 2. Execução de Scripts

Se os scripts não estiverem a correr corretamente (devido a edição no Windows), use o utilitário `dos2unix` para corrigir o formato de quebra de linha:

```bash
dos2unix nome_do_script.sh
