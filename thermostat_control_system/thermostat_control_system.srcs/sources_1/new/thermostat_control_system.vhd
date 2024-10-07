library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity thermostat_control_system is
    port (
        i_clk            : in  std_logic;
        i_rst_sync       : in  std_logic;
        
        -- Thermostat inputs
        i_current_temp   : in  std_logic_vector(6 downto 0);
        i_desired_temp   : in  std_logic_vector(6 downto 0);
        i_display_select : in  std_logic;
        i_cool           : in  std_logic;
        i_heat           : in  std_logic;
        i_furnace_hot    : in  std_logic;
        i_ac_ready       : in  std_logic;
        
        -- Thermostat outputs
        o_temp_display   : out std_logic_vector(6 downto 0);
        o_ac_on          : out std_logic;
        o_furnace_on     : out std_logic;
        o_fan_on         : out std_logic
    );
end entity thermostat_control_system;

architecture rtl of thermostat_control_system is
    type t_state is (s_idle, s_heat_on, s_furnace_ready, s_furnace_off, s_cool_on, s_ac_ready, s_ac_off);
    signal r_current_state  : t_state;
    signal r_next_state     : t_state;
    
    signal r_current_temp   : std_logic_vector(6 downto 0);
    signal r_desired_temp   : std_logic_vector(6 downto 0);
    signal r_display_select : std_logic;
    signal r_cool           : std_logic;
    signal r_heat           : std_logic;
    signal r_furnace_hot    : std_logic;
    signal r_ac_ready       : std_logic;

    signal r_temp_display   : std_logic_vector(6 downto 0);
    signal r_ac_on          : std_logic;
    signal r_furnace_on     : std_logic;
    signal r_fan_on         : std_logic;
    
    signal r_rst_count      : std_logic;
    signal r_count          : std_logic_vector(9 downto 0);
begin
    -- Input registering
    p_register_inputs : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
                r_current_temp   <= "0000000";
                r_desired_temp   <= "0000000";
                r_display_select <= '0';
                r_cool           <= '0';
                r_heat           <= '0';
                r_furnace_hot    <= '0';
                r_ac_ready       <= '0';
            else
                r_current_temp   <= i_current_temp;
                r_desired_temp   <= i_desired_temp;
                r_display_select <= i_display_select;
                r_cool           <= i_cool;
                r_heat           <= i_heat;
                r_furnace_hot    <= i_furnace_hot;
                r_ac_ready       <= i_ac_ready;
            end if;
        end if;
    end process;
    
    -- Output registering
    p_register_outputs : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
                o_temp_display <= "0000000";
                o_ac_on        <= '0';
                o_furnace_on   <= '0';
                o_fan_on       <= '0';
            else
                o_temp_display <= r_temp_display;
                o_ac_on        <= r_ac_on;
                o_furnace_on   <= r_furnace_on;
                o_fan_on       <= r_fan_on;
            end if;
        end if;
    end process;
    
    -- Clock for state machine
    p_register_states : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
                r_current_state <= s_idle;
            else
                r_current_state <= r_next_state;
            end if;
        end if;
    end process;
    
    -- Clocked process for 10-bit Johnson counter
    p_counter : process(i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' or r_rst_count = '1' then
                r_count <= (others => '0');
            else
                r_count <= r_count(8 downto 0) & (not r_count(9));
            end if;
        end if;
    end process;
                
    -- Combinatorial logic for state machine
    p_state_machine : process (r_current_state,
                               r_current_temp, r_desired_temp,
                               r_heat, r_furnace_hot,
                               r_cool, r_ac_ready, r_count) is
    begin
        r_next_state <= r_current_state;
        case r_current_state is
            when s_idle          =>
                if (r_heat = '1' and r_current_temp < r_desired_temp) then
                    r_next_state <= s_heat_on;
                elsif (r_cool = '1' and r_current_temp > r_desired_temp) then
                    r_next_state <= s_cool_on;
                end if;
            when s_heat_on       =>
                if (r_furnace_hot = '1') then
                    r_next_state <= s_furnace_ready;
                end if;
            when s_furnace_ready =>
                if not (r_heat = '1' and r_current_temp < r_desired_temp) then
                    r_next_state <= s_furnace_off;
                end if;
            when s_furnace_off   =>
                if (r_furnace_hot = '0' and r_count = "0111111111") then
                    r_next_state <= s_idle;
                end if;
            when s_cool_on       =>
                if (r_ac_ready = '1') then
                    r_next_state <= s_ac_ready;
                end if;
            when s_ac_ready      =>
                if not (r_cool = '1' and r_current_temp > r_desired_temp) then
                    r_next_state <= s_ac_off;
                end if;
            when s_ac_off        =>
                if (r_ac_ready = '0' and r_count = "1000000000") then
                    r_next_state <= s_idle;
                end if;
            when others =>
                r_next_state <= s_idle;
        end case;
    end process;
    
    -- Outputs for state machine, use selected assignment and select
    -- with r_next_state so outputs are valid at same time as
    -- current state
    with r_next_state select
        r_furnace_on <= '1' when s_heat_on | s_furnace_ready,
                        '0' when others;

    with r_next_state select       
        r_ac_on      <= '1' when s_cool_on | s_ac_ready,
                        '0' when others;
                        
    with r_next_state select       
        r_fan_on     <= '1' when s_furnace_ready | s_furnace_off | s_ac_ready | s_ac_off,
                        '0' when others;     
                        
    -- Counter with state
    with r_next_state select
        r_rst_count  <= '0' when s_furnace_off | s_ac_off,
                        '1' when others;

    -- Output for temperature display with selected assignment
    with r_display_select select
        r_temp_display <= r_current_temp when '1',
                          r_desired_temp when others;
                        
end architecture rtl;