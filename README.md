# Projecto DHCP/DNS Integrado em Linux
## Projecto_Diogo_Pascoal_GRSC_0925

Este projecto apresenta scripts de Linux para a configuração e integração dos serviços **DHCP** (Dynamic Host Configuration Protocol) e **DNS** (Domain Name System).

---
<div align="center">
    <img src="https://github.com/user-attachments/assets/4596ee1f-7e6b-4f74-998e-ea1398fd0651" alt="Vídeo demonstrando Kea DHCP e Bind DNS em acção" width="450"/>
    <br>
</div>
---

## Objectivos do Projecto

O principal objectivo é implementar o DNS, garantindo a sincronização automática e em tempo real entre a concessão de IPs e o registo de nomes de (hosts).

* **Automação:** Gestão automatizada de endereços IP via DHCP.
* **Resolução:** Configuração robusta do DNS (BIND) para resolver nomes de rede.
* **Sincronização:** Implementação do DNS para actualização imediata dos registos.

---

## Instruções de Utilização e Teste

Siga estas instruções para a correcta implementação e validação do ambiente.

<table>
  <tr>
    <td valign="top" width="60%">
      
      ### 1. Configuração de Rede (VM)
      
      O servidor deve possuir **dois adaptadores de rede**:
      * Um em modo **NAT** (Para acesso à Internet).
      * Outro em modo **LAN Segment** (Para comunicação directa e isolada com as máquinas clientes).
      
      ### 2. Execução de Scripts
      
      Se os scripts não estiverem a correr correctamente (devido a edição no Windows), use "dos2unix":
      
      dos2unix nome_do_script.sh
      ```
  </tr>
</table>
