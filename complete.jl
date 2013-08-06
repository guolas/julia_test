function equal_power_assignment(W, antennas_tx, antennas_rx, p_tx_max)
	number_of_bs = integer(size(W, 1) / antennas_tx)
	acc_matrix = kron(eye(number_of_bs), ones(antennas_tx)).'
	abs_W_2 = abs2(W)
	p_range::Array{Float64} = [0, 2^5]
	p_stream = p_range[2]* ones(number_of_bs * antennas_rx)
	p_tx = acc_matrix * abs_W_2 * p_stream
	while p_tx_max - max(p_tx) > 0
		p_range[2] = 2 * p_range[2]
		p_stream = p_range[2]* ones(number_of_bs * antennas_rx)
		p_tx = acc_matrix * abs_W_2 * p_stream 
	end
	p_stream = mean(p_range) * ones(number_of_bs * antennas_rx)
	p_tx = acc_matrix * abs_W_2 * p_stream 
	flag = check_power_condition(p_tx, p_tx_max)
	while flag != 0
		if flag == 1
			p_range[2] =  mean(p_range)
		else
			p_range[1] =  mean(p_range)
		end
		p_stream = mean(p_range) * ones(number_of_bs * antennas_rx)
		p_tx = acc_matrix * abs_W_2 * p_stream 
		flag = check_power_condition(p_tx, p_tx_max)
	end
	return mean(p_range)
end

function check_power_condition(p_tx, p_tx_max)
	if sum(p_tx .> p_tx_max) == 0
		if (p_tx_max - max(p_tx)) < 1e-3
			flag = 0
		else
			flag = -1
		end
	else
		flag = 1
	end
	return flag
end

function zf_precoding(H)
	return pinv(H)
end

function bd_precoding(H, antennas_tx, antennas_rx)
	number_of_bs = integer(size(H, 2) / antennas_tx)
	number_of_ms = integer(size(H, 1) / antennas_rx)
	W_bd = im * zeros(number_of_bs * antennas_tx, number_of_bs * antennas_rx)
	S_bd = im * zeros(number_of_ms * antennas_rx)
	U_bd = im * zeros(number_of_ms * antennas_rx, number_of_ms * antennas_rx)
	for ii in 1:number_of_bs
		rows_to_remove = [(ii - 1) * antennas_rx + 1: ii * antennas_rx]
		H_tilde = remove_rows(H, rows_to_remove)
		(U, S, V) = svd(H_tilde, false) 
		rank_H_tilde = sum(S .> eps(1.0))
		V_tilde_0 = V[:, rank_H_tilde + 1:end]
		(U, S, V) = svd(H[rows_to_remove, :] * V_tilde_0, false)
		V_1 = V[:, 1:antennas_rx]
		W_bd[:, rows_to_remove] = V_tilde_0 * V_1
		S_bd[rows_to_remove] = S[1:antennas_rx]
		U_bd[rows_to_remove, rows_to_remove] = U
	end
	return (W_bd, real(S_bd), U_bd)
end

function remove_rows(matrix, row_idx)
	row_idx = sort(row_idx, rev = true)
	rows = 1:size(matrix, 1)
	for ii in row_idx
		new_rows = [1:ii-1, ii+1:size(matrix,1)]
		matrix = matrix[new_rows, :]
	end
	return matrix
end

function get_channel_matrix(number_of_bs, tx_antennas, rx_antennas, users_per_cell = 1)
  	number_of_bs = integer(number_of_bs)
	number_rows = number_of_bs * users_per_cell * rx_antennas
	number_cols = number_of_bs * tx_antennas
	channel_matrix = sqrt(1 / 2) * (randn(number_rows, number_cols) + im * randn(number_rows, number_cols))
	return channel_matrix
end

#------------------------------
number_of_bs = 10
antennas_tx = 4
antennas_rx = 2
p_max = 10000.0
SNR = 5.0
sigma_n = p_max/10^(SNR/10)

pb_acc = kron(eye(number_of_bs), ones(antennas_tx)).'

H = get_channel_matrix(number_of_bs, antennas_tx, antennas_rx)

tic()
for ii in 1:1e4
	# BD
	W_bd, S, U = bd_precoding(H, antennas_tx, antennas_rx)
	p_tx_bd = equal_power_assignment(W_bd, antennas_tx, antennas_rx, p_max)

	stream_rate_bd = log2(1 + p_tx_bd .* S / sigma_n)

	# ZF
	W_zf = zf_precoding(H)
	p_tx_zf = equal_power_assignment(W_zf, antennas_tx, antennas_rx, p_max)
	stream_rate_zf = log2(1 + p_tx_zf * ones(number_of_bs * antennas_rx) / sigma_n)
end
toc()