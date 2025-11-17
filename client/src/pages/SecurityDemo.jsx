import { useEffect, useState } from 'react'
import axios from 'axios'
import './SecurityDemo.css'

const SecurityDemo = () => {
  const [demoComments, setDemoComments] = useState([])
  const [payload, setPayload] = useState("<script>alert('XSS')</script>")
  const [creds, setCreds] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchCreds()
    fetchDemoComments()
  }, [])

  const fetchCreds = async () => {
    try {
      const res = await axios.get('/api/root-ssh')
      setCreds(res.data.creds)
    } catch (err) {
      console.error(err)
      setError('Не удалось загрузить демонстрационные креды')
    }
  }

  const fetchDemoComments = async () => {
    try {
      const res = await axios.get('/api/demo-comments')
      setDemoComments(res.data)
    } catch (err) {
      console.error(err)
      setError('Не удалось загрузить демо-комментарии')
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await axios.post('/api/demo-comments', { content: payload })
      setPayload('')
      await fetchDemoComments()
    } catch (err) {
      console.error(err)
      setError('Не удалось сохранить комментарий')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="security-demo">
      <div className="container">
        <h1>Учебный стенд уязвимостей</h1>
        <p className="lead">
          Все примеры работают только локально на <code>localhost</code> и не используют реальные данные. 
          Используйте их, чтобы показать студентам, почему hardcoded credentials, Stored XSS и Wide-open CORS/CSRF опасны.
        </p>

        <section className="card-section">
          <h2>1. Hardcoded SSH credentials</h2>
          <p>
            Запусти скрипт ниже, чтобы показать, как легко «утекают» данные, зашитые в код:
          </p>
          <pre className="code-block">bash server/scripts/demo-ssh.sh</pre>
          {creds && (
            <div className="creds-box">
              <p><strong>Загруженные тестовые креды:</strong></p>
              <ul>
                <li>user: {creds.user}</li>
                <li>password: {creds.password}</li>
                <li>host: {creds.host}</li>
              </ul>
              <small>API: GET /api/root-ssh</small>
            </div>
          )}
        </section>

        <section className="card-section">
          <h2>2. Stored XSS в комментариях</h2>
          <p>
            Этот блок сохраняет комментарии «как есть» и выводит их через <code>dangerouslySetInnerHTML</code>, поэтому HTML и скрипты запускаются.
            Попробуй payload <code>{`<script>alert('XSS')</script>`}</code> и обнови список.
          </p>
          <form onSubmit={handleSubmit} className="demo-form">
            <textarea
              rows="4"
              value={payload}
              onChange={(e) => setPayload(e.target.value)}
              placeholder="Вставьте произвольный HTML/JS"
            />
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Сохраняем...' : 'Сохранить демо-комментарий'}
            </button>
          </form>
          {error && <p className="error">{error}</p>}
          <div className="demo-comments">
            {demoComments.length === 0 && <p>Комментариев пока нет.</p>}
            {demoComments.map((comment) => (
              <div
                key={comment.id}
                className="demo-comment"
                dangerouslySetInnerHTML={{ __html: comment.content }}
              />
            ))}
          </div>
        </section>

        <section className="card-section">
          <h2>3. Wide-open CORS + CSRF</h2>
          <p>
            На сервере включён <code>app.use(cors())</code> без ограничений, поэтому любой домен 
            может вызывать API. Чтобы продемонстрировать CSRF, открой файл <code>csrf-test.html</code> в браузере:
          </p>
          <pre className="code-block">open csrf-test.html</pre>
          <p>
            Форма автоматически отправит POST-запрос на <code>http://localhost:3000/api/comments</code>. 
            Если в браузере есть активная сессия, запрос пройдёт как будто пользователь сам отправил комментарий.
          </p>
        </section>
      </div>
    </div>
  )
}

export default SecurityDemo

