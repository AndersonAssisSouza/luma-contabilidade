-- =====================================================
-- RLS Policies for Conta Azul integration tables
-- Allows authenticated users to read data from their tenant
-- =====================================================

CREATE POLICY "tenant_read_contaazul_tokens" ON contaazul_tokens FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_contaazul_sync_log" ON contaazul_sync_log FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_categorias" ON ca_categorias FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_categorias_dre" ON ca_categorias_dre FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_centro_custos" ON ca_centro_custos FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_pessoas" ON ca_pessoas FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_produtos" ON ca_produtos FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_servicos" ON ca_servicos FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_contas_financeiras" ON ca_contas_financeiras FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_contas_receber" ON ca_contas_receber FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_contas_pagar" ON ca_contas_pagar FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_vendas" ON ca_vendas FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_notas_fiscais" ON ca_notas_fiscais FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
CREATE POLICY "tenant_read_ca_contratos" ON ca_contratos FOR SELECT USING (empresa_id = (SELECT tenant_id FROM profiles WHERE id = auth.uid()));
