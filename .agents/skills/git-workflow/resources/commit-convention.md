# Commit Convention

## Format

```text
<type> (<scope>): <short title>
<vietnamese description>
```

If the user does not provide a message, generate both title and Vietnamese description from the staged or intended diff.

## Types

- `feat`: new feature or functionality.
- `fix`: bug fix.
- `docs`: documentation updates or improvements.
- `style`: formatting or style-only changes without behavior change.
- `refactor`: code structure/readability changes without behavior change.
- `perf`: performance improvement.
- `test`: adding or modifying tests.
- `chore`: routine maintenance, cleanup, or housekeeping.
- `build`: build process or dependency changes.
- `ci`: CI/CD pipeline or automation changes.
- `revert`: revert a previous commit.
- `merge`: merge branches or resolve merge conflicts.

## Scope

Choose a concise scope from the affected area:

- feature/module name: `user-auth`, `cart`, `api`, `database`
- workflow/tooling name: `workflow`, `audit`, `git`, `hooks`, `skills`
- docs target: `readme`, `agents`, `config`

Prefer the smallest truthful scope. Use one scope only.

## Title

- Use imperative English.
- Keep it short and specific.
- Do not end with a period.
- Do not mention implementation noise unless it is the change.

## Body

Write in Vietnamese. Include concise bullets when useful:

```text
- mô tả thay đổi chính
- nêu tác động hoặc lý do
- nêu kiểm chứng nếu liên quan
```

## Examples

```text
feat (workflow): add linked skill installer
- thêm script tạo junction skill cho Codex native discovery
- cập nhật README theo luồng clone + link
```

```text
fix (audit): use Ho Chi Minh date for audit file names
- đổi tên file audit theo ngày Asia/Ho_Chi_Minh
- giữ startAt/endAt ở UTC để phục vụ truy vết
```
