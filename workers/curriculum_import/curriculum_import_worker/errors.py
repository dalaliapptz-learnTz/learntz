from __future__ import annotations


class DocumentValidationError(ValueError):
    def __init__(self, code: str, message: str, *, page_number: int | None = None):
        super().__init__(message)
        self.code = code
        self.page_number = page_number
