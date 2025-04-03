-- name: CreateTwoBodyRun :one
INSERT INTO twobody_parameters (temperature, density, version, runID, note, created_at, updated_at)
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
WHERE runID = $1
RETURNING *;

-- name: WipeTwoBodyTable :exec
DELETE FROM twobody_parameters;