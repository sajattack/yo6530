-------------------------------------------------------------------------------
-- File       : R6530.vhd
-- Author     : Thierry DAVROUX
-- Company    : Flipprojets
-- Created    : 03-01-2017
-------------------------------------------------------------------------------
-- Description: Version simplifiee d'un 6530.
--              Avec uniquement les ports A et B et le timer.
--              La RAM et la ROM ne sont pas integrees dans ce module.
--              La selection est simplifiee avec un seul "Chip Select".
--              Pas de detection de front sur PA7 (contrairement au 6532).
--              Bus d'adresses sur 4 bits (A3..A0).
-------------------------------------------------------------------------------
-- Copyright (c) Flipprojets François et Thierry DAVROUX - 2018
--               (contact@flipprojets.fr)
--
-- Concédée sous licence EUPL, version 1.2 ou – dès leur approbation par la
-- Commission européenne - versions ultérieures de l’EUPL (la «Licence»).
-- Vous ne pouvez utiliser la présente œuvre que conformément à la Licence.
-- Vous pouvez obtenir une copie de la Licence à l’adresse suivante:
--
-- https://joinup.ec.europa.eu/software/page/eupl
--
-- Sauf obligation légale ou contractuelle écrite, le logiciel distribué sous
-- la Licence est distribué «en l’état», SANS GARANTIES OU CONDITIONS QUELLES
-- QU’ELLES SOIENT, expresses ou implicites. Consultez la Licence pour les
-- autorisations et les restrictions linguistiques spécifiques relevant de la
-- Licence . 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 03-01-2017  1.0      TDX      Creation
-- 27-03-2017  1.1      TDX      Amelioration presentation (tabulations)
-------------------------------------------------------------------------------

library  IEEE ;
use      IEEE.std_logic_1164.all ;
use      IEEE.numeric_std.all ;

entity  R6530 is
        port (
            phi2   : in  std_logic                     ; -- PHI2     horloge
            rst_n  : in  std_logic                     ; -- RST      reset negatif
            cs     : in  std_logic                     ; -- CS       chip select
            rw_n   : in  std_logic                     ; -- RW       read/write
            irq_n  : out std_logic                     ; -- IRQ      interruption
            
            add    : in  std_logic_vector (3 downto 0) ; -- A3..A0   Bus d'adresses
            din    : in  std_logic_vector (7 downto 0) ; -- DI7..DI0 Bus de donnees (entrees)
            dout   : out std_logic_vector (7 downto 0) ; -- DO7..DO0 Bus de donnees (sorties)
            
            pa_in  : in  std_logic_vector (7 downto 0) ; -- PORT A   entrees
            pa_out : out std_logic_vector (7 downto 0) ; -- PORT A   sorties
            pb_in  : in  std_logic_vector (7 downto 0) ; -- PORT B   entrees
            pb_out : out std_logic_vector (7 downto 0)   -- PORT B   sorties
        );
end entity;

architecture RTL of R6530 is

            signal s_ddra               : std_logic_vector (7 downto 0) ; -- Registre DDRA
            signal s_ddrb               : std_logic_vector (7 downto 0) ; -- Registre DDRB
            signal s_ora                : std_logic_vector (7 downto 0) ; -- Registre ORA
            signal s_orb                : std_logic_vector (7 downto 0) ; -- Registre ORB
            
            signal s_dout               : std_logic_vector (7 downto 0) ; -- Sortie du bus de donnees
            
            signal s_irq_timer          : std_logic                     ; -- Etat de l'interruption par le timer
            signal s_irq_timer_en       : std_logic                     ; -- Autorisation interruption par le timer
            signal s_divider            : unsigned (9 downto 0)         ; -- Prediviseur             (valeur maxi)
            signal s_count              : unsigned (9 downto 0)         ; -- Compteur du prediviseur (compteur)
            signal s_timer              : unsigned (7 downto 0)         ; -- Decompteur du timer     (valeur en cours)

begin

    ------------------------------------------------------------------------
    -- Fonctionnement principal dependant de PHI2
    ------------------------------------------------------------------------
    
    process(phi2)
    begin
    
        if (rising_edge(phi2)) then
        
            ------------------------------------------------------------------------
            -- Tout le circuit fonctionne sur front montant du PHI2
            -- y compris la prise en compte du RESET
            ------------------------------------------------------------------------

            if (rst_n = '0') then
            
                ------------------------------------------------------------------------
                -- RESET, init de la sortie de donnees et des ports A/B
                ------------------------------------------------------------------------
                s_dout          <= (others => '1')         ; -- Sortie FF
                s_ddra          <= (others => '0')         ; -- DDRA a zero
                s_ddrb          <= (others => '0')         ; -- DDRB a zero
                s_ora           <= (others => '0')         ; --  ORA a zero
                s_orb           <= (others => '0')         ; --  ORB a zero
                
                ------------------------------------------------------------------------
                -- RESET, init du timer/diviseur et du flag d'interruption
                ------------------------------------------------------------------------
                s_timer         <= (others => '0')         ; -- Remise a zero du decompteur du timer
                s_divider       <= "0000000000"            ; -- Remise a zero du prediviseur (mode 1T)
                s_count         <= (others => '0')         ; -- Remise a zero du compteur du prediviseur
                s_irq_timer     <= '0'                     ; -- Remise a zero de l'interruption
                s_irq_timer_en  <= '0'                     ; -- Interruption non autorisee
            
            else
    
                ------------------------------------------------------------------------
                -- Traitement du timer, sur front montant du PHI2
                ------------------------------------------------------------------------
  
                if (s_count = s_divider) then
                    s_timer    <= s_timer - 1              ; -- On decremente le timer
                    s_count    <= (others => '0')          ; -- et on reinitialise le compteur du prediviseur
                    if (s_timer = "00000000") then           -- Si le timer est arrive a zero
                        s_divider   <= "0000000000"        ; --    on remet le diviseur a 1T
                        s_irq_timer <= '1'                 ; --    et on leve le flag d'interruption
                    end if ; 
                else
                    s_count <= s_count + 1                 ; -- On incremente le compteur du prediviseur
                end if ;
                
                ------------------------------------------------------------------------
                -- Acces aux registres, sur front montant du PHI2
                ------------------------------------------------------------------------
            
                if (cs = '1') then
                    -------------------------------------------------------------------------------
                    -- A condition que le CHIP SELECT soit actif, l'adressage est le suivant :   --
                    -- RW   x000 - Read/Write    ORA                                             --  
                    -- RW   x001 - Read/Write   DDRA                                             --
                    -- RW   x010 - Read/Write    ORB                                             --
                    -- RW   x011 - Read/Write   DDRB                                             --
                    --  W   .100 - Write Timer    1T                                             --
                    --  W   .101 - Write Timer    8T                                             --
                    --  W   .110 - Write Timer   64T                                             --
                    --  W   .111 - Write Timer 1024T                                             --
                    -- R    x1x0 - Read Timer                                                    --
                    -- R    x1x1 - Read Status (interrupt flag)                                  --
                    -------------------------------------------------------------------------------
                
                    if (rw_n = '0') then
                        --------------
                        -- Ecriture --
                        --------------                  

                        if (add(2) = '0') then
                            ---------------------------------------------
                            -- Acces aux registres I/O    quand A2 = 0 --
                            ---------------------------------------------

                            case add(1 downto 0) is                       
                                when "00" =>
                                    ------------------------------
                                    -- 000 : Ecriture dans ORA  --
                                    ------------------------------
                                    s_ora <= din ;
                                when "01" =>
                                    ------------------------------
                                    -- 001 : Ecriture dans DDRA --
                                    ------------------------------
                                    s_ddra <= din ;
                                when "10" =>
                                    ------------------------------
                                    -- 010 : Ecriture dans ORB  --
                                    ------------------------------
                                    s_orb <= din ;
                                when "11" =>
                                    ------------------------------
                                    -- 011 : Ecriture dans DDRB --
                                    ------------------------------
                                    s_ddrb <= din ;
                                when others =>
                                    null ;
                            end case ;
                                
                        else
                            -------------------------------------------------
                            -- Acces aux registres Timer      quand A2 = 1 --
                            -------------------------------------------------

                            ---------------------------------------------
                            -- A3 active ou non les interruptions      --
                            ---------------------------------------------

                            s_irq_timer_en <= add(3)     ; -- Autorisation des interruptions selon le bit A3
                            s_irq_timer    <= '0'        ; -- Efface le flag d'interruption
                            s_timer <= unsigned(din) - 1 ; -- Valeur initiale du timer
                            s_count <= (others => '0')   ; -- Mise a zero du compteur du prediviseur
                                
                            case add(1 downto 0) is                          
                                when "00" =>
                                    --------------------------
                                    -- 100 : diviseur    1T --
                                    --------------------------
                                    s_divider <= "0000000000" ; -- Valeur maxi du compteur = 0
                                when "01" =>
                                    --------------------------
                                    -- 101 : diviseur    8T --
                                    --------------------------
                                    s_divider <= "0000000111" ; -- Valeur maxi du compteur = 7
                                when "10" =>
                                    --------------------------
                                    -- 110 : diviseur   64T --
                                    --------------------------
                                    s_divider <= "0000111111" ; -- Valeur maxi du compteur = 63
                                when "11" =>
                                    --------------------------
                                    -- 111 : diviseur 1024T --
                                    --------------------------
                                    s_divider <= "1111111111" ; -- Valeur maxi du compteur = 1023
                                when others =>
                                    null ;
                            end case ;
                                
                        end if ; -- Fin des ecritures --
                          
                    else
                        -------------
                        -- Lecture --
                        -------------
                          
                        if (add(2) = '0') then
                            ---------------------------------------------
                            -- Acces aux registres I/O    quand A2 = 0 --
                            ---------------------------------------------

                            case add(1 downto 0) is
                                when "00" =>
                                    ---------------------------
                                    -- 000 : Lecture de ORA  --
                                    ---------------------------
                                    s_dout <= ((s_ddra and s_ora) or (pa_in and not(s_ddra))) ; -- Lecture du port en entree ou des latches de sortie
                                when "01" =>
                                    ---------------------------
                                    -- 001 : Lecture de DDRA --
                                    ---------------------------
                                    s_dout <= s_ddra ;
                                when "10" =>
                                    ---------------------------
                                    -- 010 : Lecture de ORB  --
                                    ---------------------------
                                    s_dout <= ((s_ddrb and s_orb) or (pb_in and not(s_ddrb))) ; -- Lecture du port en entree ou des latches de sortie
                                when "11" =>
                                    ---------------------------
                                    -- 011 : Lecture de DDRB --
                                    ---------------------------
                                    s_dout <= s_ddrb ;
                                when others =>
                                    null ;

                            end case ;
                                                            
                        else
                            ---------------------------------------------
                            -- Acces au timer et status quand A2 = 1   --
                            ---------------------------------------------

                            if (add(0) = '0') then
                                ----------------------------------------
                                -- 1x0 : Lecture du TIMER             --
                                -- A3 active ou non les interruptions --
                                ----------------------------------------
                                s_irq_timer_en <= add(3)            ; -- Autorisation des interruptions selon le bit A3
                            
                                s_dout <= std_logic_vector(s_timer) ; -- Valeur courante du timer
                                if not (s_timer = "00000000") then
                                    s_irq_timer <= '0'              ; -- Efface le flag d'interruption du timer, sauf si interruption en cours
                                end if ;
                            else
                                -----------------------------
                                -- 1x1 : Lecture du STATUS --
                                -----------------------------
                                s_dout <= s_irq_timer & "0000000"   ; -- Registre de status (flag d'interruption)
                            end if ;
                      
                        end if ;
                                                                                  
                    end if ; -- Fin des lectures --
                          
                end if ; -- Fin des acces dependant du chip select --
                     
            end if ; -- Fin des traitements hors RESET

            ------------------------------------------------------------------------
            -- Signal d'interruption en sortie, si interruption generee et autorisee
            ------------------------------------------------------------------------
    
            irq_n <= not (s_irq_timer and s_irq_timer_en) ;            
          
        end if ; -- Fin du traitement sur front montant de PHI2
                
        ------------------------------------------------------------------------
        -- Sorties sur les ports A et B, sur front descendant du PHI2
        ------------------------------------------------------------------------

        if (falling_edge(phi2)) then
            pa_out <= ((s_ora and s_ddra) or (pa_in and not(s_ddra))) ; -- Sortie sur PORT A, uniquement pour les bits en sorties (a "1" dans DDRA) + copie des entrees
            pb_out <= ((s_orb and s_ddrb) or (pb_in and not(s_ddrb))) ; -- Sortie sur PORT B, uniquement pour les bits en sorties (a "1" dans DDRB) + copie des entrees
        end if ;
     
    end process ;
    
    ------------------------------------------------------------------------
    -- Sortie sur le bus de donnees
    ------------------------------------------------------------------------
    
    dout <= s_dout when ((cs = '1') and (rw_n = '1')) else (others => '1') ; -- Si lecture et chip select, sinon FF

end architecture;

