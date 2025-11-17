import { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import axios from 'axios'
import ReactMarkdown from 'react-markdown'
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter'
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism'
import { useAuth } from '../context/AuthContext'
import { FiUser, FiCalendar, FiEye, FiTag, FiEdit2, FiTrash2, FiHeart } from 'react-icons/fi'
import toast from 'react-hot-toast'
import './Article.css'

const Article = () => {
  const { slug } = useParams()
  const { user } = useAuth()
  const navigate = useNavigate()
  const [article, setArticle] = useState(null)
  const [comments, setComments] = useState([])
  const [newComment, setNewComment] = useState('')
  const [loading, setLoading] = useState(true)
  const [subscribed, setSubscribed] = useState(false)

  useEffect(() => {
    fetchArticle()
  }, [slug])

  useEffect(() => {
    if (article) {
      fetchComments()
      if (user && article.author) {
        checkSubscription()
      }
    }
  }, [article, user])

  const fetchArticle = async () => {
    try {
      const response = await axios.get(`/api/articles/${slug}`)
      setArticle(response.data)
    } catch (error) {
      console.error('Ошибка загрузки статьи:', error)
      toast.error('Статья не найдена')
    } finally {
      setLoading(false)
    }
  }

  const fetchComments = async () => {
    if (!article) return
    try {
      const response = await axios.get(`/api/comments/article/${article.id}`)
      setComments(response.data)
    } catch (error) {
      console.error('Ошибка загрузки комментариев:', error)
    }
  }

  const checkSubscription = async () => {
    if (!user || !article?.author) return
    try {
      const response = await axios.get(`/api/subscriptions/${article.author.id}/check`)
      setSubscribed(response.data.subscribed)
    } catch (error) {
      console.error('Ошибка проверки подписки:', error)
    }
  }

  const handleSubscribe = async () => {
    if (!user) {
      toast.error('Войдите, чтобы подписаться')
      return
    }
    try {
      if (subscribed) {
        await axios.delete(`/api/subscriptions/${article.author.id}`)
        setSubscribed(false)
        toast.success('Подписка отменена')
      } else {
        await axios.post(`/api/subscriptions/${article.author.id}`)
        setSubscribed(true)
        toast.success('Подписка оформлена')
      }
    } catch (error) {
      toast.error('Ошибка подписки')
    }
  }

  const handleComment = async (e) => {
    e.preventDefault()
    if (!user) {
      toast.error('Войдите, чтобы оставить комментарий')
      return
    }
    try {
      const response = await axios.post('/api/comments', {
        content: newComment,
        articleId: article.id
      })
      setComments([response.data, ...comments])
      setNewComment('')
      toast.success('Комментарий добавлен')
    } catch (error) {
      toast.error('Ошибка добавления комментария')
    }
  }

  const handleDeleteArticle = async () => {
    if (!window.confirm('Удалить статью?')) return
    try {
      await axios.delete(`/api/articles/${article.id}`)
      toast.success('Статья удалена')
      navigate('/')
    } catch (error) {
      toast.error('Ошибка удаления статьи')
    }
  }

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (loading) {
    return <div className="loading">Загрузка статьи...</div>
  }

  if (!article) {
    return <div className="no-article">Статья не найдена</div>
  }

  const canEdit = user && (user.id === article.authorId || user.role === 'admin')

  return (
    <div className="article-page">
      <div className="container">
        <article className="article-full">
          {article.coverImage && (
            <div className="article-cover-full">
              <img src={article.coverImage} alt={article.title} />
            </div>
          )}

          <div className="article-header">
            <div className="article-meta-full">
              {article.category && (
                <Link to={`/?category=${article.category.id}`} className="article-category">
                  {article.category.name}
                </Link>
              )}
              <span className="article-date">
                <FiCalendar /> {formatDate(article.createdAt)}
              </span>
              <span className="article-views">
                <FiEye /> {article.views} просмотров
              </span>
            </div>

            <h1>{article.title}</h1>

            <div className="article-author-info">
              <Link to={`/user/${article.author.id}`} className="author-link">
                {article.author.avatar ? (
                  <img src={article.author.avatar} alt={article.author.username} />
                ) : (
                  <FiUser />
                )}
                <div>
                  <strong>{article.author.username}</strong>
                  {article.author.bio && <p>{article.author.bio}</p>}
                </div>
              </Link>
              {user && user.id !== article.author.id && (
                <button
                  onClick={handleSubscribe}
                  className={`btn-subscribe ${subscribed ? 'subscribed' : ''}`}
                >
                  <FiHeart /> {subscribed ? 'Подписан' : 'Подписаться'}
                </button>
              )}
            </div>

            {canEdit && (
              <div className="article-actions">
                <Link to={`/edit-article/${article.id}`} className="btn-edit">
                  <FiEdit2 /> Редактировать
                </Link>
                <button onClick={handleDeleteArticle} className="btn-delete">
                  <FiTrash2 /> Удалить
                </button>
              </div>
            )}

            {article.tags && article.tags.length > 0 && (
              <div className="article-tags-full">
                {article.tags.map((tag) => (
                  <Link key={tag.id} to={`/?tag=${tag.slug}`} className="article-tag">
                    <FiTag /> {tag.name}
                  </Link>
                ))}
              </div>
            )}
          </div>

          <div className="article-body">
            {user ? (
              <ReactMarkdown
                components={{
                  code({ node, inline, className, children, ...props }) {
                    const match = /language-(\w+)/.exec(className || '')
                    return !inline && match ? (
                      <SyntaxHighlighter
                        style={vscDarkPlus}
                        language={match[1]}
                        PreTag="div"
                        {...props}
                      >
                        {String(children).replace(/\n$/, '')}
                      </SyntaxHighlighter>
                    ) : (
                      <code className={className} {...props}>
                        {children}
                      </code>
                    )
                  }
                }}
              >
                {article.content}
              </ReactMarkdown>
            ) : (
              <div className="article-locked">
                <div className="lock-icon">🔒</div>
                <h3>Полный текст статьи доступен только для зарегистрированных пользователей</h3>
                <p>Зарегистрируйтесь или войдите, чтобы читать полные статьи и оставлять комментарии.</p>
                <div className="auth-buttons">
                  <Link to="/register" className="btn btn-primary">Зарегистрироваться</Link>
                  <Link to="/login" className="btn btn-outline">Войти</Link>
                </div>
                <div className="preview-text">
                  <p><strong>Превью:</strong></p>
                  <div className="preview-content">
                    {article.excerpt || article.content.substring(0, 500) + '...'}
                  </div>
                </div>
              </div>
            )}
          </div>
        </article>

        <div className="comments-section">
          <h2>Комментарии ({comments.length})</h2>

          {user ? (
            <form onSubmit={handleComment} className="comment-form">
              <textarea
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="Напишите комментарий..."
                rows="4"
              />
              <button type="submit" className="btn-primary">
                Отправить
              </button>
            </form>
          ) : (
            <p className="login-prompt">
              <Link to="/login">Войдите</Link>, чтобы оставить комментарий
            </p>
          )}

          <div className="comments-list">
            {comments.map((comment) => (
              <div key={comment.id} className="comment-item">
                <div className="comment-header">
                  <Link to={`/user/${comment.user.id}`} className="comment-author">
                    {comment.user.avatar ? (
                      <img src={comment.user.avatar} alt={comment.user.username} />
                    ) : (
                      <FiUser />
                    )}
                    <strong>{comment.user.username}</strong>
                  </Link>
                  <span className="comment-date">{formatDate(comment.createdAt)}</span>
                </div>
                <div className="comment-content">{comment.content}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Article

