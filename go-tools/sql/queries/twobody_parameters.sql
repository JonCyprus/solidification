-- name: CreateTwoBodyRun :one
INSERT INTO twobody_parameters (temperature, density, version, run_id, note, created_at, updated_at)
VALUES(
       $1,
       $2,
       $3,
       $4,
       $5,
       $6,
       $7
      ) RETURNING *;

-- name: RemoveRunByID :one
DELETE FROM twobody_parameters
WHERE run_id = $1
RETURNING *;

-- name: WipeTwoBodyTable :exec
DELETE FROM twobody_parameters;

-- name: ListAllTwoBodyParams :many
SELECT * FROM twobody_parameters;

-- name: SelectTwoBodyParamByRunID :one
SELECT * FROM twobody_parameters
WHERE run_id = $1;