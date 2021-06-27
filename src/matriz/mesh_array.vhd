library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use work.array_types.all;

entity mesh_array is
  generic (
    N : natural := 5;
    M : natural := 5
  );

  port (
    clock     : in  std_logic;
    reset     : in  std_logic;
    matrix_a  : in  vector_of_numbers(0 to N*N-1);
    matrix_b  : in  vector_of_numbers(0 to N*N-1);
    matrix_c  : out vector_of_numbers(0 to N*N-1)
  );

end entity mesh_array;

architecture behave of mesh_array is

  signal connections :  vector_of_numbers(0 to (N+1)*(2*M)-1) := (others => (others => 'Z'));

  begin

    matrix_rows : for i in 0 to N-1 generate
      matrix_columns : for j in 0 to M-1 generate

        left_bord_condition : if (j = 0) generate
            single_Element : entity work.PE(behave)
            port map (
              clock         => clock,
              reset         => reset,
              left_input    => connections((2*M)*i + 2*j),
              right_input   => connections((2*M)*i + 2*j+1),
              left_output   => connections((2*M)*(i+1) + 2*j),
              right_output  => connections((2*M)*(i+1) + 2*(j+1)),
              result        => matrix_c(M*i + j)
            );
        end generate left_bord_condition;

        right_bord_condition : if (j = M-1) generate
            single_Element : entity work.PE(behave)
            port map (
              clock         => clock,
              reset         => reset,
              left_input    => connections((2*M)*i + 2*j),
              right_input   => connections((2*M)*i + 2*j+1),
              left_output   => connections((2*M)*(i+1) + 2*j-1),
              right_output  => connections((2*M)*(i+1) + 2*j+1),
              result        => matrix_c(M*i + j)
            );
        end generate right_bord_condition;

        general_condition : if ((j > 0) and (j < M-1)) generate
            single_Element : entity work.PE(behave)
            port map (
              clock         => clock,
              reset         => reset,
              left_input    => connections((2*M)*i + 2*j),
              right_input   => connections((2*M)*i + 2*j+1),
              left_output   => connections((2*M)*(i+1) + 2*j-1),
              right_output  => connections((2*M)*(i+1) + 2*(j+1)),
              result        => matrix_c(M*i + j)
            );
          end generate general_condition;

      end generate matrix_columns;
    end generate matrix_rows;

    matrix_multiply : process(reset, clock)
      variable index : natural;
    begin

      if (reset = '1') then
        index := 0;
        for j in 0 to M-1 loop
          connections(2*j) <= (others => '0');
          connections(2*j + 1) <= (others => '0');
        end loop;
      elsif (rising_edge(clock)) then
        for j in 0 to M-1 loop
          if (j mod 2 = 0) then
            connections(2*j) <= matrix_b(M*index + j);
            connections(2*j + 1) <= matrix_a(M*j + index);
          else
            connections(2*j) <= matrix_a(M*j + index);
            connections(2*j + 1) <= matrix_b(M*index + j);
          end if;
        end loop;

        index := index + 1;
        if index >= N then
          index := 0;
        end if;

      end if;

    end process matrix_multiply;

end architecture behave;
