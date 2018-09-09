--*************************************************************--
--*************** Module of FIR low pass filter ***************--
--*************************************************************--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

entity firfilter is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		i_data : in std_logic_vector(7 downto 0);
		o_data : out std_logic_vector(7 downto 0)
	);
end firfilter;

architecture rtl of firfilter is

	-- pipeline data
	type t_data_pipe is array (0 to 3) of std_logic_vector(7 downto 0);
	
	-- coefficient for FIR filter
	type t_coeff is array (0 to 3) of std_logic_vector(7 downto 0);
	
	type t_mult is array (0 to 3) of std_logic_vector(15 + 1 downto 0);
	type t_add_st0 is array (0 to 1) of std_logic_vector(15 + 2 downto 0);
	
	signal coeff : t_coeff;
	signal p_data : t_data_pipe;
	signal r_mult : t_mult;
	signal r_add_st0 : t_add_st0;
	signal r_add_st1 : std_logic_vector(15 + 2 downto 0);
 
begin

----------------------------------------------------------//
-----    Process of input         ------------------------//
----------------------------------------------------------//
	p_input : process (rstn, clk)
	begin
		if (rstn = '0') then -- active low reset
			p_data <= (others => (others => '0'));
			coeff <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
		
		   -- a pipeline of chain register for FIR filter
			p_data <= std_logic_vector(i_data) & p_data(0 to p_data'LENGTH - 2);
			
			-- put dummy coefficient data into 4 tap FIR filter
			coeff(0) <= "00111111";
			coeff(1) <= "00111111";
			coeff(2) <= "00111111";
			coeff(3) <= "00111111";
		end if;
	end process p_input;

----------------------------------------------------------//
-------Process of multiplication -------------------------//
----------------------------------------------------------//
	-- the input multiply with coefficient
	p_multiply : process (clk, rstn)
	begin
		if (rstn = '0') then
			r_mult <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			for k in 0 to 3 loop
				r_mult(k) <= '0' & p_data(k) * coeff(k);
			end loop;
		end if;
	end process p_multiply;

----------------------------------------------------------//
------- Stage 0                 --------------------------//
----------------------------------------------------------// 
   -- the first stage where the addition of two multiplication's result
	p_add_stage_0 : process (clk, rstn)
	begin
		if (rstn = '0') then
			r_add_st0 <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			for k in 0 to 1 loop
				r_add_st0(k) <= '0' & (r_mult(2 * k) + r_mult(2 * k + 1));
			end loop;
		end if;
	end process p_add_stage_0;

----------------------------------------------------------//
------- Stage 1                 --------------------------//
----------------------------------------------------------// 
	-- the stage where the final two are added up
   p_add_stage_1 : process (clk, rstn)
	begin
		if (rstn = '0') then
			r_add_st1 <= (others => '0');
		elsif (rising_edge(clk)) then
			r_add_st1 <= r_add_st0(0) + r_add_st0(1);
		end if;
	end process p_add_stage_1;

----------------------------------------------------------//
------- Final stage: sum up     --------------------------//
----------------------------------------------------------// 
   -- the result of final adder
	p_output : process (clk, rstn)
	begin
		if (rstn = '0') then
			o_data <= (others => '0');
		elsif (rising_edge(clk)) then
		-- output data is the 8 MSB
			o_data <= std_logic_vector(r_add_st1(15 downto 8));
		end if;
	end process p_output;
 
end rtl;