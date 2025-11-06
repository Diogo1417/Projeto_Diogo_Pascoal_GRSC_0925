# Projecto DHCP/DNS Integrado em Linux
## Projecto_Diogo_Pascoal_GRSC_0925

Este projecto apresenta scripts de Linux para a configuração e integração dos serviços **DHCP** (Dynamic Host Configuration Protocol) e **DNS** (Domain Name System).

---

### Demonstração do Projecto

<div align="center">
    <img src="https://github.com/user-attachments/assets/4596ee1f-7e6b-4f74-998e-ea1398fd0651" alt="Vídeo demonstrando Kea DHCP e Bind DNS em acção" width="450"/>
    <br>
    <p>Este vídeo demonstra o **Script DHCP (Kea) + DNS (Bind)** em acção, validando a sincronização entre os serviços.</p>
</div>

---

## Objectivos do Projecto

O principal objectivo é implementar o **Dynamic DNS (DDNS)**, garantindo a sincronização automática e em tempo real entre a concessão de IPs e o registo de nomes de anfitriões (*hostnames*).

* **Automação:** Gestão automatizada de endereços IP via DHCP.
* **Resolução:** Configuração robusta do DNS (BIND) para resolver nomes de rede.
* **Sincronização:** Implementação do DDNS para actualização imediata dos registos.

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
      
      Se os scripts não estiverem a correr correctamente (devido a edição no Windows), use o utilitário <code>dos2unix</code>:
      
      ```bash
      dos2unix nome_do_script.sh
      ```
    </td>
    
    <td valign="top" width="40%" align="center">
      
      ### 3. Teste em Máquinas Clientes
      
      Para forçar o cliente a pedir um novo IP (e validar o DDNS), utilize os seguintes comandos:
      
      | Sistema Operacional | Libertar IP (*Release*) | Pedir Novo IP (*Renew*) |
      | :--- | :--- | :--- |
      | **Windows** | `ipconfig /release` | `ipconfig /renew` |
      | **Linux** | `sudo dhclient -r [interface]` | `sudo dhclient [interface]` |
      
    </td>
  </tr>
</table>

---

## Detalhes de Implementação

<table>
  <tr>
    <td valign="top" width="65%">
      <p>A funcionalidade de **DDNS** é a chave deste projecto. A imagem de apoio ao lado (se for um *screenshot* de uma consola ou ficheiro de configuração) pode ilustrar aspectos da implementação ou *logs* que confirmem o registo de um cliente.</p>
      
      <p>Consulte as pastas <code>DHCP/</code> e <code>DNS/</code> para aceder aos ficheiros de configuração detalhados.</p>
    </td>
    
    <td valign="top" width="35%" align="right">
      <img 
        src="image_70143f.png" 
        alt="Imagem de apoio sobre os detalhes de implementação do DDNS" 
        width="250" 
      />
    </td>
  </tr>
</table>

---

## Autor e Licença

* **Autor:** Diogo Pascoal
* **Licença:** Este projecto está sob a licença [ADICIONE A LICENÇA AQUI, ex: MIT].
