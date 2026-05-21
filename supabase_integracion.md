# Integracion Supabase

Los archivos SQL del profesor se mantienen sin cambios en la carpeta anterior al proyecto.

## Orden de ejecucion sugerido

1. Ejecutar el setup base que cree `public.cuentas` y `public.transacciones`.
2. Ejecutar `supabase/sql/01_preparar_scoring_preaprobados.sql`.
3. Ejecutar `scoring_preaprobados.sql`.
4. Ejecutar `seed_agencias_asesores.sql`.
5. Ejecutar `supabase/sql/02_compatibilidad_antes_seed_1800.sql`.
6. Ejecutar `supabase/sql/03_seed_scoring_1800_compatible.sql`.

## Variables para correr la app

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```

Si no se envian esas variables, la app abre en modo demo para mostrar el frontend.

## Tablas y vistas que consume la app

- `perfiles_clientes`
- `scores_transaccionales`
- `creditos_preaprobados`
- `fichas_campo`
- `vw_pbi_agencias`
- `vw_pbi_asesores`
- `vw_pbi_kpis_piloto`

## Observaciones sin editar los SQL originales

- Los scripts del profesor asumen que ya existen `public.cuentas` y `public.transacciones`.
- `scores_transaccionales` debe permitir conflicto por `user_id` para que funcione la funcion `calcular_score_transaccional`.
- El seed masivo crea datos simulados, pero depende de usuarios compatibles con `auth.users`.
- Si el profesor pide mantener los SQL intactos, esos ajustes deben manejarse como setup complementario o desde Supabase antes de cargar la data.
- `03_seed_scoring_1800_compatible.sql` es una copia del seed de 1,800 clientes con un casteo a `BIGINT` para evitar overflow al generar telefonos. El original del profesor no se modifica.
