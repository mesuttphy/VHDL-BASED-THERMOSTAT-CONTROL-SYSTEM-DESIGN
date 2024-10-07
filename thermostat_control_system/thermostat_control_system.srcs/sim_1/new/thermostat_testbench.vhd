library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity thermostat_testbench is
end entity thermostat_testbench;

architecture sim of thermostat_testbench is
    component thermostat_control_system is
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
    end component thermostat_control_system;
    
    signal i_clk            : std_logic := '0';
    signal i_rst_sync       : std_logic;
    
    -- Thermostat inputs
    signal i_current_temp   : std_logic_vector(6 downto 0);
    signal i_desired_temp   : std_logic_vector(6 downto 0);
    signal i_display_select : std_logic;
    signal i_cool           : std_logic;
    signal i_heat           : std_logic;
    signal i_furnace_hot    : std_logic;
    signal i_ac_ready       : std_logic;
    
    -- Thermostat outputs
    signal o_temp_display   : std_logic_vector(6 downto 0);
    signal o_ac_on          : std_logic;
    signal o_furnace_on     : std_logic;
    signal o_fan_on         : std_logic;

begin
    -- Instantiate thermostat component
    thermostat : thermostat_control_system port map (
            i_clk            => i_clk,
            i_rst_sync       => i_rst_sync,
            i_current_temp   => i_current_temp,
            i_desired_temp   => i_desired_temp,
            i_display_select => i_display_select,
            i_cool           => i_cool,
            i_heat           => i_heat,
            i_furnace_hot    => i_furnace_hot,
            i_ac_ready       => i_ac_ready,
            o_temp_display   => o_temp_display,
            o_ac_on          => o_ac_on,
            o_furnace_on     => o_furnace_on,
            o_fan_on         => o_fan_on
        );

    -- Assign clock, 10ns period
    i_clk <= not i_clk after 5ns;
    
    -- Assign reset, high for 50ns then low for remainder
    i_rst_sync <= '1', '0' after 50ns; 

    -- Simulation process
    process
    begin
        -- Initialize signals
        i_current_temp   <= "0011001";
        i_desired_temp   <= "0100101";
        i_display_select <= '0';
        i_cool           <= '0';
        i_heat           <= '0';
        i_furnace_hot    <= '0';
        i_ac_ready       <= '0';
        wait for 50ns;
        wait for 50ns;
        
        -- Change display_select
        i_display_select <= '1';
        wait for 50ns;
        
        -- Return display_select to previous value
        i_display_select <= '0';
        wait for 50ns;
        
        --------------------------------------------------
        -- Iterate through cooling states of state machine
        --------------------------------------------------
        -- i_desired_temp > i_current_temp, so state should remain s_idle
        i_cool           <= '1';
        wait for 50ns;
        
        -- i_desired_temp < i_current_temp, so state should move to s_cool_on
        i_current_temp   <= "0100101";
        i_desired_temp   <= "0011001";
        wait for 50ns;
        
        -- i_ac_ready will be '1', so state should move to s_ac_ready
        i_ac_ready       <= '1';
        wait for 50ns;
        
        -- Temperature reaches desired temperature, so should move to s_ac_off state
        i_current_temp   <= "0011001";
        wait for 50ns;
        
        -- AC powered off, so ac no longer ready, should move to s_idle state after 20 clock cycles
        i_ac_ready       <= '0';
        wait for 250ns;
        
        -- Turn cool off before proceeding
        i_cool           <= '0';
        wait for 50ns;

        --------------------------------------------------
        -- Iterate through heating states of state machine
        --------------------------------------------------
        -- i_desired_temp = i_current_temp, so state should remain s_idle
        i_heat           <= '1';
        wait for 50ns;

        -- i_desired_temp > i_current_temp, so state should move to s_heat_on
        i_current_temp   <= "0011001";
        i_desired_temp   <= "0100101";
        wait for 50ns;
        
        -- i_furnace_hot will be '1', so state should move to s_furnace_ready
        i_furnace_hot    <= '1';
        wait for 50ns;
        
        -- Temperature reaches desired temperature, so should move to s_furnace_off state
        i_current_temp   <= "0100101";
        wait for 50ns;
        
        -- Furnace powered off, so furnace no longer hot, should move to s_idle state after 10 clock cycles
        i_furnace_hot    <= '0';
        wait for 150ns;
        
        -- Turn heat off before proceeding
        i_heat           <= '0';
        wait for 50ns;

        -- End simulation
        wait;
    end process;
end architecture sim; 