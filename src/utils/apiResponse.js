// ─────────────────────────────────────────────────────────────────────────────
// Standardized API Response Helpers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Send a success response.
 * @param {import('express').Response} res
 * @param {*} data
 * @param {string} [message='Success']
 * @param {number} [statusCode=200]
 */
function success(res, data = null, message = 'Success', statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

/**
 * Send a created (201) response.
 * @param {import('express').Response} res
 * @param {*} data
 * @param {string} [message='Created']
 */
function created(res, data = null, message = 'Created') {
  return success(res, data, message, 201);
}

/**
 * Send an error response.
 * @param {import('express').Response} res
 * @param {string} message
 * @param {number} [statusCode=400]
 * @param {*} [errors=null]
 */
function error(res, message = 'Bad Request', statusCode = 400, errors = null) {
  const body = {
    success: false,
    message,
  };
  if (errors) body.errors = errors;
  return res.status(statusCode).json(body);
}

/**
 * Send a paginated response.
 * @param {import('express').Response} res
 * @param {*} data
 * @param {{ page: number, limit: number, total: number }} pagination
 * @param {string} [message='Success']
 */
function paginated(res, data, pagination, message = 'Success') {
  const { page, limit, total } = pagination;
  return res.status(200).json({
    success: true,
    message,
    data,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
}

module.exports = { success, created, error, paginated };
